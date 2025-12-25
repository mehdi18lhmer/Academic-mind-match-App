import * as cdk from 'aws-cdk-lib';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as snsSubscriptions from 'aws-cdk-lib/aws-sns-subscriptions';
import * as logs from 'aws-cdk-lib/aws-logs';
import { Construct } from 'constructs';

export interface MonitoringStackProps extends cdk.StackProps {
  clusterName: string;
  serviceName: string;
  loadBalancerArn: string;
  alertEmail: string;
}

export class MonitoringStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: MonitoringStackProps) {
    super(scope, id, props);

    // SNS Topic for alerts
    const alertTopic = new sns.Topic(this, 'AcademicMatchAlerts', {
      displayName: 'AcademicMatch Alerts',
      topicName: 'academicmatch-alerts'
    });

    // Email subscription for alerts
    alertTopic.addSubscription(
      new snsSubscriptions.EmailSubscription(props.alertEmail)
    );

    // CloudWatch Dashboard
    const dashboard = new cloudwatch.Dashboard(this, 'AcademicMatchDashboard', {
      dashboardName: 'AcademicMatch-Production',
      periodOverride: cloudwatch.PeriodOverride.AUTO,
    });

    // ECS Service Metrics
    const ecsServiceWidget = new cloudwatch.GraphWidget({
      title: 'ECS Service Metrics',
      width: 12,
      height: 6,
      left: [
        new cloudwatch.Metric({
          namespace: 'AWS/ECS',
          metricName: 'CPUUtilization',
          dimensionsMap: {
            ServiceName: props.serviceName,
            ClusterName: props.clusterName,
          },
          statistic: 'Average',
        }),
        new cloudwatch.Metric({
          namespace: 'AWS/ECS',
          metricName: 'MemoryUtilization',
          dimensionsMap: {
            ServiceName: props.serviceName,
            ClusterName: props.clusterName,
          },
          statistic: 'Average',
        }),
      ],
      right: [
        new cloudwatch.Metric({
          namespace: 'AWS/ECS',
          metricName: 'RunningTaskCount',
          dimensionsMap: {
            ServiceName: props.serviceName,
            ClusterName: props.clusterName,
          },
          statistic: 'Average',
        }),
      ],
    });

    // Application Load Balancer Metrics
    const albWidget = new cloudwatch.GraphWidget({
      title: 'Load Balancer Metrics',
      width: 12,
      height: 6,
      left: [
        new cloudwatch.Metric({
          namespace: 'AWS/ApplicationELB',
          metricName: 'RequestCount',
          dimensionsMap: {
            LoadBalancer: props.loadBalancerArn.split('/').slice(-3).join('/'),
          },
          statistic: 'Sum',
        }),
        new cloudwatch.Metric({
          namespace: 'AWS/ApplicationELB',
          metricName: 'TargetResponseTime',
          dimensionsMap: {
            LoadBalancer: props.loadBalancerArn.split('/').slice(-3).join('/'),
          },
          statistic: 'Average',
        }),
      ],
      right: [
        new cloudwatch.Metric({
          namespace: 'AWS/ApplicationELB',
          metricName: 'HTTPCode_ELB_5XX_Count',
          dimensionsMap: {
            LoadBalancer: props.loadBalancerArn.split('/').slice(-3).join('/'),
          },
          statistic: 'Sum',
        }),
        new cloudwatch.Metric({
          namespace: 'AWS/ApplicationELB',
          metricName: 'HTTPCode_Target_5XX_Count',
          dimensionsMap: {
            LoadBalancer: props.loadBalancerArn.split('/').slice(-3).join('/'),
          },
          statistic: 'Sum',
        }),
      ],
    });

    // RDS Metrics Widget
    const rdsWidget = new cloudwatch.GraphWidget({
      title: 'RDS Database Metrics',
      width: 12,
      height: 6,
      left: [
        new cloudwatch.Metric({
          namespace: 'AWS/RDS',
          metricName: 'CPUUtilization',
          dimensionsMap: {
            DBInstanceIdentifier: 'academicmatch-database', // This should match your RDS instance
          },
          statistic: 'Average',
        }),
        new cloudwatch.Metric({
          namespace: 'AWS/RDS',
          metricName: 'DatabaseConnections',
          dimensionsMap: {
            DBInstanceIdentifier: 'academicmatch-database',
          },
          statistic: 'Average',
        }),
      ],
    });

    // Add widgets to dashboard
    dashboard.addWidgets(ecsServiceWidget, albWidget);
    dashboard.addWidgets(rdsWidget);

    // Alarms
    
    // High CPU Usage Alarm
    const highCpuAlarm = new cloudwatch.Alarm(this, 'HighCpuAlarm', {
      alarmName: 'AcademicMatch-High-CPU',
      alarmDescription: 'Alarm when ECS service CPU exceeds 80%',
      metric: new cloudwatch.Metric({
        namespace: 'AWS/ECS',
        metricName: 'CPUUtilization',
        dimensionsMap: {
          ServiceName: props.serviceName,
          ClusterName: props.clusterName,
        },
        statistic: 'Average',
      }),
      threshold: 80,
      evaluationPeriods: 2,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
    });
    highCpuAlarm.addAlarmAction(new cloudwatch.SnsAction(alertTopic));

    // High Memory Usage Alarm
    const highMemoryAlarm = new cloudwatch.Alarm(this, 'HighMemoryAlarm', {
      alarmName: 'AcademicMatch-High-Memory',
      alarmDescription: 'Alarm when ECS service memory exceeds 85%',
      metric: new cloudwatch.Metric({
        namespace: 'AWS/ECS',
        metricName: 'MemoryUtilization',
        dimensionsMap: {
          ServiceName: props.serviceName,
          ClusterName: props.clusterName,
        },
        statistic: 'Average',
      }),
      threshold: 85,
      evaluationPeriods: 2,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
    });
    highMemoryAlarm.addAlarmAction(new cloudwatch.SnsAction(alertTopic));

    // High Error Rate Alarm
    const highErrorRateAlarm = new cloudwatch.Alarm(this, 'HighErrorRateAlarm', {
      alarmName: 'AcademicMatch-High-Error-Rate',
      alarmDescription: 'Alarm when 5XX error rate is high',
      metric: new cloudwatch.Metric({
        namespace: 'AWS/ApplicationELB',
        metricName: 'HTTPCode_Target_5XX_Count',
        dimensionsMap: {
          LoadBalancer: props.loadBalancerArn.split('/').slice(-3).join('/'),
        },
        statistic: 'Sum',
      }),
      threshold: 10,
      evaluationPeriods: 2,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
    });
    highErrorRateAlarm.addAlarmAction(new cloudwatch.SnsAction(alertTopic));

    // Service Task Count Alarm
    const lowTaskCountAlarm = new cloudwatch.Alarm(this, 'LowTaskCountAlarm', {
      alarmName: 'AcademicMatch-Low-Task-Count',
      alarmDescription: 'Alarm when running task count is below minimum',
      metric: new cloudwatch.Metric({
        namespace: 'AWS/ECS',
        metricName: 'RunningTaskCount',
        dimensionsMap: {
          ServiceName: props.serviceName,
          ClusterName: props.clusterName,
        },
        statistic: 'Average',
      }),
      threshold: 1,
      evaluationPeriods: 1,
      comparisonOperator: cloudwatch.ComparisonOperator.LESS_THAN_THRESHOLD,
    });
    lowTaskCountAlarm.addAlarmAction(new cloudwatch.SnsAction(alertTopic));

    // Log Insights Queries
    const logGroup = logs.LogGroup.fromLogGroupName(this, 'AppLogGroup', '/aws/ecs/academicmatch');

    // CloudFormation Outputs
    new cdk.CfnOutput(this, 'DashboardUrl', {
      value: `https://${this.region}.console.aws.amazon.com/cloudwatch/home?region=${this.region}#dashboards:name=${dashboard.dashboardName}`,
      description: 'CloudWatch Dashboard URL',
    });

    new cdk.CfnOutput(this, 'AlertTopicArn', {
      value: alertTopic.topicArn,
      description: 'SNS Topic ARN for alerts',
    });
  }
}
