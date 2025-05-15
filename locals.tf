locals {
  resource_name_prefix = join("-", compact([var.project, var.venue, "%s"]))
  account_id = data.aws_caller_identity.current.account_id
  default_tags = length(var.default_tags) == 0 ? {
    application : var.app_name,
  } : var.default_tags
  private_application_subnet_cidr_blocks = [for s in data.aws_subnet.private_application_subnet : s.cidr_block]
  common_tags  = {}
  cluster_name = var.deployment_name
  subnet_map   = data.aws_subnet.private_application_subnet
  ami = jsondecode(data.aws_ssm_parameter.eks_amis.value)[var.cluster_version]
  #iam_arn = data.aws_ssm_parameter.eks_iam_node_role.value
  mergednodegroups = { for name, ng in var.nodegroups :
    name => {
      use_name_prefix            = false
      create_iam_role            = false
      create_launch_template     = false
      min_size                   = ng.min_size != null ? ng.min_size : 1
      max_size                   = ng.max_size != null ? ng.max_size : 10
      desired_size               = ng.desired_size != null ? ng.desired_size : 3
      ami_id                     = local.ami
      instance_types             = ng.instance_types != null ? ng.instance_types : ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
      capacity_type              = ng.capacity_type != null ? ng.capacity_type : "ON_DEMAND"
      iam_role_arn               = ng.iam_role_arn != null ? ng.iam_role_arn : aws_iam_role.cluster_iam_role.arn
      launch_template_id       = ng.launch_template_id != null ? ng.launch_template_id : aws_launch_template.node_group_launch_template.id
      enable_bootstrap_user_data = true
      iam_role_additional_policies = { AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy" }
      pre_bootstrap_user_data    = <<-EOT
            sudo sed -i 's/^net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/' /etc/sysctl.conf && sudo sysctl -p |true
        EOT
      metadata_options = {
        "http_endpoint" : ng.metadata_options != null ? lookup(ng.metadata_options, "http_endpoint", null) : null
        "http_put_response_hop_limit" : ng.metadata_options != null ? lookup(ng.metadata_options, "http_put_response_hop_limit", null) : null
        "http_tokens" : ng.metadata_options != null ? lookup(ng.metadata_options, "http_tokens", null) : null
      }
      block_device_mappings = ng.block_device_mappings != null ? { for device_name, mapping in ng.block_device_mappings :
        device_name => {
          device_name = mapping.device_name
          ebs = {
            volume_size           = mapping.ebs.volume_size
            volume_type           = mapping.ebs.volume_type
            encrypted             = mapping.ebs.encrypted
            kms_key_id            = data.aws_kms_key.current.arn
            delete_on_termination = mapping.ebs.delete_on_termination
          }
        }
      } : {} /* empty set if null*/ 
    }
  }
  openidc_provider_domain_name = trimprefix(module.eks.cluster_oidc_issuer_url, "https://")
}
