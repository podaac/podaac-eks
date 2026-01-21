# PO.DAAC-EKS

PO.DAAC EKS is a basic installation of EKS with EBS and EFS support. It allows for interaction via kubectl. It is meant to be a basic deployment infrastructure that can be used to deploy k8s pods (e.g. Airflow, websites, etc).

## Backend Initialization

Before running Terraform, you must configure the backend for state storage. This is done using a `.backend` file (e.g., `tfvars/<env>.backend`) to specify backend configuration options.

Initialize Terraform with the backend configuration:

```
terraform init -reconfigure -backend-config="tfvars/<env>.backend"
```

**Example:**
For the `sit` environment:
```
terraform init -reconfigure -backend-config="tfvars/sit.backend"
```

## Installation

To deploy to a given environment, utilize the appropriate tfvars file:

```
terraform apply --var-file=tfvars/<env>.tfvars
```

**Example:**
For the `sit` environment:
```
terraform apply --var-file=tfvars/sit.tfvars
```

When complete, you should have an EKS cluster running in your AWS region with the most recent AMI for the cluster version you're running.
