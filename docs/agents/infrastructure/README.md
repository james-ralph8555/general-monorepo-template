# Infrastructure Development Guide for AI Agents

This guide provides comprehensive instructions for AI agents to implement infrastructure as code and deployment automation in this monorepo.

## Overview

Infrastructure development in this monorepo uses:
- **AWS CDK**: For cloud infrastructure as code
- **Terraform**: For multi-cloud and provider-agnostic resources  
- **Kubernetes**: For container orchestration and deployment
- **Docker/OCI**: For container image building with Bazel
- **CI/CD**: GitHub Actions with Bazel for deployment automation
- **Monitoring**: Observability and alerting setup

## Setup and Configuration

### Prerequisites

Ensure you're in the development environment:
```bash
nix develop
# Available tools: aws-cli, terraform, kubectl, docker
aws --version
terraform --version
kubectl version --client
```

### Bazel Configuration

Add to MODULE.bazel:
```python
bazel_dep(name = "rules_oci", version = "1.5.0")
bazel_dep(name = "rules_python", version = "0.31.0")  # for CDK
bazel_dep(name = "aspect_rules_js", version = "1.40.0")  # for CDK

# Container base images
oci = use_extension("@rules_oci//oci:extensions.bzl", "oci")
oci.pull(
    name = "distroless_python",
    image = "gcr.io/distroless/python3",
    platforms = ["linux/amd64", "linux/arm64"],
)
use_repo(oci, "distroless_python")
```

## Project Structure

### AWS CDK Infrastructure
```
infra/aws-cdk/
├── BUILD.bazel
├── app.py
├── cdk.json
├── requirements.txt
├── stacks/
│   ├── __init__.py
│   ├── network_stack.py
│   ├── compute_stack.py
│   └── storage_stack.py
├── constructs/
│   ├── __init__.py
│   └── custom_construct.py
└── tests/
    └── test_stacks.py
```

### Terraform Modules
```
infra/terraform/
├── BUILD.bazel
├── main.tf
├── variables.tf
├── outputs.tf
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── eks/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    ├── dev/
    │   └── terraform.tfvars
    └── prod/
        └── terraform.tfvars
```

### Kubernetes Manifests
```
infra/k8s/
├── BUILD.bazel
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
├── overlays/
│   ├── dev/
│   │   └── kustomization.yaml
│   └── prod/
│       └── kustomization.yaml
└── helm/
    └── my-app/
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
```

## BUILD.bazel Patterns

### AWS CDK Application
```python
load("@rules_python//python:defs.bzl", "py_binary", "py_library")

py_library(
    name = "stacks",
    srcs = glob(["stacks/*.py"]),
    deps = [
        "@pip//aws-cdk-lib",
        "@pip//constructs",
    ],
    visibility = ["//visibility:public"],
)

py_binary(
    name = "app",
    srcs = ["app.py"],
    main = "app.py",
    deps = [":stacks"],
    env = {
        "CDK_DEFAULT_ACCOUNT": "$(CDK_DEFAULT_ACCOUNT)",
        "CDK_DEFAULT_REGION": "$(CDK_DEFAULT_REGION)",
    },
)

# CDK commands
sh_binary(
    name = "synth",
    srcs = ["scripts/cdk-synth.sh"],
    data = [":app"],
    env = {"PYTHONPATH": "$(location :app).runfiles"},
)

sh_binary(
    name = "deploy",
    srcs = ["scripts/cdk-deploy.sh"],
    data = [":app"],
    env = {"PYTHONPATH": "$(location :app).runfiles"},
)

sh_binary(
    name = "destroy",
    srcs = ["scripts/cdk-destroy.sh"],
    data = [":app"],
    env = {"PYTHONPATH": "$(location :app).runfiles"},
)
```

### Terraform Configuration
```python
load("@aspect_rules_terraform//terraform:defs.bzl", "terraform_plan", "terraform_apply")

terraform_plan(
    name = "plan",
    srcs = glob(["*.tf"]),
    var_files = ["environments/dev/terraform.tfvars"],
)

terraform_apply(
    name = "apply",
    plan = ":plan",
)

# Multi-environment targets
terraform_plan(
    name = "plan_prod",
    srcs = glob(["*.tf"]),
    var_files = ["environments/prod/terraform.tfvars"],
)
```

### Container Images
```python
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_tarball", "oci_push")

oci_image(
    name = "app_image",
    base = "@distroless_python",
    entrypoint = ["/usr/bin/python3"],
    cmd = ["app.py"],
    tars = [
        "//apps/backend:app_tar",
    ],
    env = {
        "PYTHONPATH": "/app",
        "PORT": "8080",
    },
)

oci_tarball(
    name = "app_image_tar",
    image = ":app_image",
    repo_tags = ["myapp:latest"],
)

oci_push(
    name = "push_to_registry",
    image = ":app_image",
    repository = "gcr.io/my-project/myapp",
)
```

### Kubernetes Deployments
```python
load("@rules_k8s//k8s:objects.bzl", "k8s_objects")
load("@io_bazel_rules_k8s//k8s:object.bzl", "k8s_object")

k8s_object(
    name = "deployment",
    kind = "deployment",
    template = "deployment.yaml",
    images = {
        "myapp:placeholder": ":app_image",
    },
)

k8s_object(
    name = "service",
    kind = "service", 
    template = "service.yaml",
)

k8s_objects(
    name = "k8s_dev",
    objects = [
        ":deployment",
        ":service",
    ],
)
```

## AWS CDK Implementation

### Basic Stack Definition
```python
# stacks/network_stack.py
from aws_cdk import Stack, aws_ec2 as ec2
from constructs import Construct

class NetworkStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)
        
        # VPC with public/private subnets
        self.vpc = ec2.Vpc(
            self, "VPC",
            max_azs=2,
            cidr="10.0.0.0/16",
            nat_gateways=1,
            subnet_configuration=[
                ec2.SubnetConfiguration(
                    name="public",
                    subnet_type=ec2.SubnetType.PUBLIC,
                    cidr_mask=24,
                ),
                ec2.SubnetConfiguration(
                    name="private",
                    subnet_type=ec2.SubnetType.PRIVATE_WITH_EGRESS,
                    cidr_mask=24,
                ),
            ],
        )
```

### Application Stack
```python
# stacks/compute_stack.py
from aws_cdk import Stack, aws_ecs as ecs, aws_ecs_patterns as ecs_patterns
from constructs import Construct

class ComputeStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, vpc, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)
        
        # ECS cluster
        cluster = ecs.Cluster(
            self, "Cluster",
            vpc=vpc,
            container_insights=True,
        )
        
        # Fargate service
        self.service = ecs_patterns.ApplicationLoadBalancedFargateService(
            self, "Service",
            cluster=cluster,
            memory_limit_mib=1024,
            cpu=512,
            task_image_options=ecs_patterns.ApplicationLoadBalancedTaskImageOptions(
                image=ecs.ContainerImage.from_registry("myapp:latest"),
                container_port=8080,
                environment={
                    "ENV": "production",
                },
            ),
            public_load_balancer=True,
        )
```

### CDK App Entry Point
```python
# app.py
#!/usr/bin/env python3
import aws_cdk as cdk
from stacks.network_stack import NetworkStack
from stacks.compute_stack import ComputeStack

app = cdk.App()

# Environment configuration
env = cdk.Environment(
    account=app.node.try_get_context("account"),
    region=app.node.try_get_context("region"),
)

# Create stacks
network_stack = NetworkStack(app, "NetworkStack", env=env)
compute_stack = ComputeStack(
    app, "ComputeStack",
    vpc=network_stack.vpc,
    env=env,
)

app.synth()
```

## Terraform Implementation

### Provider Configuration
```hcl
# main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
  
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "infrastructure/terraform.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region = var.aws_region
}
```

### VPC Module
```hcl
# modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = var.name
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.name}-public-${count.index + 1}"
    Type = "public"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = var.name
  }
}
```

### EKS Module
```hcl
# modules/eks/main.tf
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.public_access_cidrs
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-workers"
  node_role_arn   = aws_iam_role.workers.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_capacity
    min_size     = var.min_capacity
  }

  instance_types = var.instance_types
  
  depends_on = [
    aws_iam_role_policy_attachment.workers_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.workers_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.workers_AmazonEC2ContainerRegistryReadOnly,
  ]
}
```

## Kubernetes Implementation

### Base Deployment
```yaml
# base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: myapp:placeholder
        ports:
        - containerPort: 8080
        env:
        - name: PORT
          value: "8080"
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

### Service Definition
```yaml
# base/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
  type: ClusterIP
```

### Kustomization
```yaml
# overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base

patchesStrategicMerge:
- deployment-patch.yaml

replicas:
- name: myapp
  count: 5

images:
- name: myapp:placeholder
  newName: gcr.io/my-project/myapp
  newTag: v1.2.3
```

## CI/CD Implementation

### GitHub Actions Workflow
```yaml
# .github/workflows/infrastructure.yml
name: Infrastructure

on:
  push:
    branches: [main]
    paths: ['infra/**']
  pull_request:
    paths: ['infra/**']

jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Nix
      uses: cachix/install-nix-action@v22
      
    - name: Enter dev shell
      run: nix develop --command bash -c "echo 'Dev environment ready'"
      
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-west-2
    
    - name: Terraform Plan
      run: nix develop --command bazel run //infra/terraform:plan
      
    - name: CDK Synth
      run: nix develop --command bazel run //infra/aws-cdk:synth

  deploy:
    runs-on: ubuntu-latest
    needs: plan
    if: github.ref == 'refs/heads/main'
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Nix
      uses: cachix/install-nix-action@v22
      
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-west-2
    
    - name: Deploy Infrastructure
      run: nix develop --command bazel run //infra/terraform:apply
      
    - name: Deploy CDK
      run: nix develop --command bazel run //infra/aws-cdk:deploy
```

## Container Image Building

### Multi-stage Dockerfile
```dockerfile
# Build stage
FROM python:3.11-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# Runtime stage  
FROM gcr.io/distroless/python3
COPY --from=builder /root/.local /usr/local
COPY src/ /app/
WORKDIR /app
EXPOSE 8080
CMD ["python", "main.py"]
```

### OCI Image with Bazel
```python
# Production-ready container
oci_image(
    name = "production_image",
    base = "@distroless_python",
    entrypoint = ["/usr/bin/python3"],
    cmd = ["/app/main.py"],
    tars = [
        "//apps/backend:app_layer",
        "//packages/shared:shared_layer",
    ],
    env = {
        "PYTHONPATH": "/app",
        "PORT": "8080",
        "ENV": "production",
    },
    user = "nonroot",
)
```

## Monitoring and Observability

### Prometheus Configuration
```yaml
# monitoring/prometheus.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'myapp'
      static_configs:
      - targets: ['myapp-service:80']
      metrics_path: '/metrics'
```

### Grafana Dashboard
```python
# Dashboard as code
py_binary(
    name = "generate_dashboards",
    srcs = ["scripts/generate_dashboards.py"],
    deps = [
        "@pip//grafanalib",
    ],
    data = ["//monitoring:dashboard_templates"],
)
```

### CloudWatch Alarms (CDK)
```python
# In CDK stack
alarm = cloudwatch.Alarm(
    self, "HighErrorRate",
    metric=cloudwatch.Metric(
        namespace="AWS/ApplicationELB",
        metric_name="HTTPCode_Target_5XX_Count",
        dimensions_map={
            "LoadBalancer": load_balancer.load_balancer_full_name,
        },
        statistic="Sum",
        period=Duration.minutes(5),
    ),
    threshold=10,
    evaluation_periods=2,
)
```

## Testing

### Infrastructure Tests
```python
# Test CDK stacks
py_test(
    name = "test_stacks",
    srcs = ["tests/test_stacks.py"],
    deps = [
        ":stacks",
        "@pip//aws-cdk-lib",
        "@pip//pytest",
    ],
)
```

### Terraform Testing
```python
# Terratest integration
go_test(
    name = "terraform_test",
    srcs = ["test/terraform_test.go"],
    deps = [
        "@com_github_gruntwork_io_terratest//modules/terraform",
        "@com_github_stretchr_testify//assert",
    ],
    data = glob(["*.tf"]),
)
```

### Integration Tests
```bash
#!/bin/bash
# test/integration_test.sh

# Deploy to test environment
bazel run //infra/terraform:apply_test

# Run application tests
kubectl apply -f k8s/test/
kubectl wait --for=condition=ready pod -l app=test-app

# Test endpoints
curl -f http://test-app.local/health
curl -f http://test-app.local/api/status

# Cleanup
kubectl delete -f k8s/test/
bazel run //infra/terraform:destroy_test
```

## Common Tasks

### Adding New Infrastructure

1. Choose appropriate tool (CDK for AWS-native, Terraform for multi-cloud)
2. Create resource definitions following existing patterns
3. Add to BUILD.bazel with appropriate targets
4. Write tests for infrastructure code
5. Update CI/CD pipeline to include new resources

### Environment Management

1. Use separate directories/files for each environment
2. Parameterize configurations with variables
3. Use different state backends for isolation
4. Apply least privilege access for each environment

### Secrets Management

1. Use AWS Secrets Manager or similar
2. Reference secrets in infrastructure code, don't embed
3. Rotate secrets regularly through automation
4. Use service accounts and IAM roles where possible

## Troubleshooting

### CDK/Terraform Failures
- Check AWS credentials and permissions
- Verify resource limits and quotas
- Use `--verbose` flags for detailed output
- Check CloudFormation events for detailed errors

### Container Build Issues
- Verify base images are accessible
- Check layer sizes and optimize if needed
- Ensure all dependencies are included in image
- Test images locally before deployment

### Kubernetes Deployment Problems
- Check resource quotas and limits
- Verify image pull secrets are configured
- Check logs: `kubectl logs deployment/myapp`
- Validate YAML syntax and resource definitions

### CI/CD Pipeline Issues
- Verify secrets are configured correctly
- Check environment variables and contexts
- Ensure proper permissions for deployment targets
- Review build logs for specific error messages

## Security Best Practices

### Infrastructure Security
- Use least privilege IAM policies
- Enable encryption at rest and in transit
- Configure VPC security groups restrictively
- Use private subnets for application workloads

### Container Security
- Use distroless or minimal base images
- Run containers as non-root users
- Scan images for vulnerabilities
- Sign container images and verify signatures

### Secrets and Configuration
- Never commit secrets to version control
- Use managed secret services
- Rotate credentials regularly
- Audit secret access and usage

## Examples

See [language implementations](../../examples/language-implementations.md) for complete examples of infrastructure patterns in this monorepo.