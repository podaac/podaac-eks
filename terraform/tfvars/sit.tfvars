app_name        = "eks"
cluster_version = "1.32"
default_tags    = {}
deployment_name = "podaac-services-sit-eks"
environment     = "sit"
nodegroups = {
  "defaultNodeGroup": {
    "desired_size": 2,
    "instance_types": [
      "m5.xlarge"
    ],
    "max_size": 2,
    "min_size": 1
  }
}
project = "podaac-services"
venue   = "sit"

ami_rotation_period = 5

/* We hard code for now until we have time to work around the EBS cross-AZ issue */
/* us-west-2b */
eks_subnet_id = "subnet-0d15606f25bd4047b"
