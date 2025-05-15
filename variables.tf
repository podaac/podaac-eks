variable "app_name" {
  type        = string
  description = "Application name"
  default     = "eks"
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy to"
  default     = "us-west-2"
}

variable "default_tags" {
  type    = map(string)
  default = {}
}


variable "deployment_name" {
  type    = string
}

variable "nodegroups" {
  description = "The nodegroups configuration"

  type = map(object({
    create_iam_role            = optional(bool)
    iam_role_arn               = optional(string)
    ami_id                     = optional(string)
    min_size                   = optional(number)
    max_size                   = optional(number)
    desired_size               = optional(number)
    instance_types             = optional(list(string))
    capacity_type              = optional(string)
    enable_bootstrap_user_data = optional(bool)
    launch_template_id       = optional(string)
    metadata_options           = optional(map(any))
    block_device_mappings = optional(map(object({
      device_name = string
      ebs = object({
        volume_size           = number
        volume_type           = string
        encrypted             = bool
        delete_on_termination = bool
      })
    })))
  }))

  default = {
    defaultNodeGroup = {
      instance_types = ["m5.xlarge"]
      min_size       = 1
      max_size       = 1
      desired_size   = 1
    }
  }
}

variable "project" {
  description = "The podaac project its installed into"
  type        = string
  default     = "podaac-services"
}

variable "venue" {
  description = "The podaac venue its installed into"
  type        = string
  default     = "sit"
}

variable "environment" {
  type        = string
  description = "The environment in which to deploy to"
  default = "myenv"
}

variable "cluster_version" {
  type    = string
  default = "1.32"
}

