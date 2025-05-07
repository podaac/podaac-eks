app_name        = "eks"
cluster_version = "1.32"
default_tags    = {}
deployment_name = "podaac-services-sit-eks"
environment     = "sit"
nodegroups = {
  "defaultNodeGroup": {
    "desired_size": 1,
    "instance_types": [
      "m5.xlarge"
    ],
    "max_size": 1,
    "min_size": 1
  }
}
project = "podaac-services"
venue   = "sit"
