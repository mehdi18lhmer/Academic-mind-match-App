#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { AcademicMatchStack } from './lib/academicmatch-stack';

const app = new cdk.App();

// Get environment variables
const account = app.node.tryGetContext('account') || process.env.CDK_DEFAULT_ACCOUNT;
const region = app.node.tryGetContext('region') || process.env.CDK_DEFAULT_REGION || 'us-east-1';

new AcademicMatchStack(app, 'AcademicMatchStack', {
  env: { account, region },
  description: 'Infrastructure stack for AcademicMatch web application',
  stackName: 'academicmatch-production'
});
