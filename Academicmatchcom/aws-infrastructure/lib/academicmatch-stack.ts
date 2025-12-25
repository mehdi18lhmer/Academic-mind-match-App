import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecsPatterns from 'aws-cdk-lib/aws-ecs-patterns';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import { Construct } from 'constructs';

export class AcademicMatchStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Create VPC
    const vpc = new ec2.Vpc(this, 'AcademicMatchVpc', {
      maxAzs: 2,
      natGateways: 1,
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: 'public',
          subnetType: ec2.SubnetType.PUBLIC,
        },
        {
          cidrMask: 24,
          name: 'private-with-egress',
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
        },
        {
          cidrMask: 24,
          name: 'private-isolated',
          subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
        }
      ],
    });

    // Database credentials secret
    const dbCredentials = new secretsmanager.Secret(this, 'AcademicMatchDbCredentials', {
      secretName: 'academicmatch-db-credentials',
      generateSecretString: {
        secretStringTemplate: JSON.stringify({ username: 'academicmatch_admin' }),
        generateStringKey: 'password',
        excludeCharacters: '"@/\\',
        passwordLength: 32,
      },
      description: 'Database credentials for AcademicMatch PostgreSQL instance',
    });

    // RDS PostgreSQL Database
    const database = new rds.DatabaseInstance(this, 'AcademicMatchDatabase', {
      engine: rds.DatabaseInstanceEngine.postgres({
        version: rds.PostgresEngineVersion.VER_15_4,
      }),
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MICRO),
      vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
      },
      credentials: rds.Credentials.fromSecret(dbCredentials),
      databaseName: 'academicmatch',
      allocatedStorage: 20,
      maxAllocatedStorage: 100,
      deleteAutomatedBackups: true,
      backupRetention: cdk.Duration.days(7),
      deletionProtection: true,
      removalPolicy: cdk.RemovalPolicy.SNAPSHOT,
      enablePerformanceInsights: true,
    });

    // JWT Secret
    const jwtSecret = new secretsmanager.Secret(this, 'AcademicMatchJwtSecret', {
      secretName: 'academicmatch-jwt-secret',
      generateSecretString: {
        passwordLength: 64,
        excludeCharacters: '"@/\\',
      },
      description: 'JWT signing secret for AcademicMatch authentication',
    });

    // ECS Cluster
    const cluster = new ecs.Cluster(this, 'AcademicMatchCluster', {
      vpc,
      clusterName: 'academicmatch-cluster',
      containerInsights: true,
    });

    // CloudWatch Log Group
    const logGroup = new logs.LogGroup(this, 'AcademicMatchLogGroup', {
      logGroupName: '/aws/ecs/academicmatch',
      retention: logs.RetentionDays.ONE_MONTH,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // Task execution role
    const taskExecutionRole = new iam.Role(this, 'AcademicMatchTaskExecutionRole', {
      assumedBy: new iam.ServicePrincipal('ecs-tasks.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AmazonECSTaskExecutionRolePolicy'),
      ],
    });

    // Add permissions to access secrets
    dbCredentials.grantRead(taskExecutionRole);
    jwtSecret.grantRead(taskExecutionRole);

    // Task role
    const taskRole = new iam.Role(this, 'AcademicMatchTaskRole', {
      assumedBy: new iam.ServicePrincipal('ecs-tasks.amazonaws.com'),
    });

    // ECS Fargate Service with Application Load Balancer
    const fargateService = new ecsPatterns.ApplicationLoadBalancedFargateService(this, 'AcademicMatchService', {
      cluster,
      cpu: 512,
      memoryLimitMiB: 1024,
      desiredCount: 2,
      taskImageOptions: {
        image: ecs.ContainerImage.fromRegistry('nginx:latest'), // Placeholder - will be updated via CI/CD
        containerPort: 5000,
        logDriver: ecs.LogDrivers.awsLogs({
          streamPrefix: 'academicmatch',
          logGroup: logGroup,
        }),
        executionRole: taskExecutionRole,
        taskRole: taskRole,
        secrets: {
          DATABASE_URL: ecs.Secret.fromSecretsManager(dbCredentials, 'DATABASE_URL'),
          JWT_SECRET: ecs.Secret.fromSecretsManager(jwtSecret),
        },
        environment: {
          NODE_ENV: 'production',
          PORT: '5000',
        },
      },
      publicLoadBalancer: true,
      serviceName: 'academicmatch-service',
      enableLogging: true,
    });

    // Allow ECS tasks to connect to RDS
    database.connections.allowDefaultPortFrom(fargateService.service, 'ECS to RDS');

    // Auto Scaling
    const scaling = fargateService.service.autoScaleTaskCount({
      minCapacity: 2,
      maxCapacity: 10,
    });

    scaling.scaleOnCpuUtilization('CpuScaling', {
      targetUtilizationPercent: 70,
      scaleInCooldown: cdk.Duration.minutes(10),
      scaleOutCooldown: cdk.Duration.minutes(5),
    });

    scaling.scaleOnMemoryUtilization('MemoryScaling', {
      targetUtilizationPercent: 80,
    });

    // Store parameters in SSM for easy access
    new ssm.StringParameter(this, 'DatabaseEndpointParam', {
      parameterName: '/academicmatch/database/endpoint',
      stringValue: database.instanceEndpoint.hostname,
      description: 'RDS PostgreSQL database endpoint',
    });

    new ssm.StringParameter(this, 'LoadBalancerDnsParam', {
      parameterName: '/academicmatch/alb/dns-name',
      stringValue: fargateService.loadBalancer.loadBalancerDnsName,
      description: 'Application Load Balancer DNS name',
    });

    // CloudFormation Outputs
    new cdk.CfnOutput(this, 'LoadBalancerDNS', {
      value: fargateService.loadBalancer.loadBalancerDnsName,
      description: 'DNS name of the load balancer',
      exportName: 'AcademicMatch-LoadBalancer-DNS',
    });

    new cdk.CfnOutput(this, 'DatabaseEndpoint', {
      value: database.instanceEndpoint.hostname,
      description: 'RDS PostgreSQL database endpoint',
      exportName: 'AcademicMatch-Database-Endpoint',
    });

    new cdk.CfnOutput(this, 'ClusterName', {
      value: cluster.clusterName,
      description: 'ECS Cluster name',
      exportName: 'AcademicMatch-Cluster-Name',
    });

    new cdk.CfnOutput(this, 'ServiceName', {
      value: fargateService.service.serviceName,
      description: 'ECS Service name',
      exportName: 'AcademicMatch-Service-Name',
    });
  }
}
