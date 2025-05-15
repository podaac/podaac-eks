# PO.DAAC-EKS

PO.DAAC EKS is a basic installation of EKS with EBS and EFS support. It allows for interaction via kubectl. It is meant to be a basic deployment infrastrucutre that can be used to deploy k8s pods (e.g. Airflow, websites, etc).

## Installation

We must first init the terraform for this environment. You must provide a bucket for initialization. 

```
terraform init -reconfigure -backend-config="bucket=$BUCKET"
```

to deploy to a given environment, utilize the appropriate tfvars file.

```
terraform apply --var-file=tfvars/sit.tfvars
```

When complete, you should have an EKS cluster running in your AWS region with the most recent AMI for the cluster version you're running.

