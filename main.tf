terraform {
  backend "s3" {
    bucket               = "podaac-sit-services-airlfow"
    workspace_key_prefix = "eks/tfstates"
    key                  = "terraform.tfstate"
    region               = "us-west-2"
    encrypt              = true
  }
}

resource "aws_iam_role" "cluster_iam_role" {
  name = "${local.cluster_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com" # or the appropriate AWS service
        },
      },
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com" # or the appropriate AWS service
        },
      },
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "s3.amazonaws.com" # or the appropriate AWS service
        },
      },
    ],
  })

  permissions_boundary = data.aws_iam_policy.permissions_boundary.arn

}

resource "aws_iam_role_policy_attachment" "container-reg" {
  role       = aws_iam_role.cluster_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ebscsi" {
  role       = aws_iam_role.cluster_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
resource "aws_iam_role_policy_attachment" "eks-cni" {
  role       = aws_iam_role.cluster_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "worker-node" {
  role       = aws_iam_role.cluster_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "ssm-automation" {
  role       = aws_iam_role.cluster_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
}
resource "aws_iam_role_policy_attachment" "ssm-managed-instance" {
  role       = aws_iam_role.cluster_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "cloudwatch-agent" {
  role       = aws_iam_role.cluster_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

/*
# Batch, Step Functions allowances
resource "aws_iam_role_policy_attachment" "node-policy-batch-snf" {
  role       = aws_iam_role.cluster_iam_role.name
  policy_arn = aws_iam_policy.custom_policy_batch_snf.arn
}


resource "aws_iam_policy" "custom_policy_batch_snf" {
  name        = "${local.cluster_name}-eks-batch-snf-policy" # Give a unique name to your policy
  path        = "/"                                # Optionally, specify a path for the policy
  description = "A custom policy that provides access to Batch and Step function commands."

  policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "batch:SubmitJob",
            "Resource": [
                "arn:aws:batch:*:*:job-definition/svc*",
                "arn:aws:batch:*:*:job-queue/svc*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [ 
              "batch:DescribeJobs",
              "states:ListExecutions",
              "states:ListMapRuns"
            ],
            "Resource": "*"
        }
     ]
    }
  EOF
}*/

/*
# Allow for key management system 
resource "aws_iam_role_policy_attachment" "node-policy-kms" {
  role       = aws_iam_role.cluster_iam_role.name
  policy_arn = aws_iam_policy.custom_policy_kms_for_eks.arn
}

resource "aws_iam_policy" "custom_policy_kms_for_eks" {
  name        = "${local.cluster_name}-eks-kms-policy" # Give a unique name to your policy
  path        = "/"                                # Optionally, specify a path for the policy
  description = "A custom policy that provides access to KMS"

  policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "KMSforEKS",
                "Effect": "Allow",
                "Action": [
                    "kms:Decrypt",
                    "kms:ReEncryptTo",
                    "kms:GenerateDataKeyWithoutPlaintext",
                    "kms:DescribeKey",
                    "kms:CreateGrant",
                    "kms:ReEncryptFrom"
                ],
                "Resource": "*"
            }
        ]
    }
  EOF
}
*/

resource "aws_iam_role_policy_attachment" "node-policy" {
  role       = aws_iam_role.cluster_iam_role.name
  policy_arn = aws_iam_policy.custom_policy.arn
}

resource "aws_iam_policy" "custom_policy" {
  name        = "${local.cluster_name}-eks-policy" # Give a unique name to your policy
  path        = "/"                                # Optionally, specify a path for the policy
  description = "A custom policy that provides access to EC2, ECR, SNS, etc."

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "ec2:CreateTags",
            "Resource": [
                "arn:aws:ec2:*:*:volume/*",
                "arn:aws:ec2:*:*:snapshot/*"
            ],
            "Condition": {
                "StringEquals": {
                    "ec2:CreateAction": [
                        "CreateVolume",
                        "CreateSnapshot"
                    ]
                }
            }
        },
        {
                "Sid": "KMSforEKS",
                "Effect": "Allow",
                "Action": [
                    "kms:Decrypt",
                    "kms:ReEncryptTo",
                    "kms:GenerateDataKeyWithoutPlaintext",
                    "kms:DescribeKey",
                    "kms:CreateGrant",
                    "kms:ReEncryptFrom"
                ],
                "Resource": "*"
        },
        {
            "Sid": "confluencebatch",
            "Effect": "Allow",
            "Action": "batch:SubmitJob",
            "Resource": [
                "arn:aws:batch:*:*:job-definition/svc*",
                "arn:aws:batch:*:*:job-queue/svc*"
            ]
        },
        {
            "Sid": "confluencesnf",
            "Effect": "Allow",
            "Action": [ 
              "batch:DescribeJobs",
              "states:ListExecutions",
              "states:ListMapRuns"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "ec2:CreateVolume",
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "aws:RequestTag/ebs.csi.aws.com/cluster": "true"
                }
            }
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": "ec2:CreateVolume",
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "aws:RequestTag/CSIVolumeName": "*"
                }
            }
        },
        {
            "Sid": "VisualEditor3",
            "Effect": "Allow",
            "Action": "ec2:DeleteVolume",
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
                }
            }
        },
        {
            "Sid": "VisualEditor4",
            "Effect": "Allow",
            "Action": "ec2:DeleteVolume",
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/CSIVolumeName": "*"
                }
            }
        },
        {
            "Sid": "VisualEditor5",
            "Effect": "Allow",
            "Action": "ec2:DeleteVolume",
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/kubernetes.io/created-for/pvc/name": "*"
                }
            }
        },
        {
            "Sid": "VisualEditor6",
            "Effect": "Allow",
            "Action": "ec2:DeleteSnapshot",
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/CSIVolumeSnapshotName": "*"
                }
            }
        },
        {
            "Sid": "VisualEditor7",
            "Effect": "Allow",
            "Action": "ec2:DeleteSnapshot",
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
                }
            }
        },
        {
            "Sid": "VisualEditor8",
            "Effect": "Allow",
            "Action": "ec2:CreateTags",
            "Resource": "arn:aws:ec2:*:*:network-interface/*"
        },
        {
            "Sid": "VisualEditor9",
            "Effect": "Allow",
            "Action": "ec2:DeleteTags",
            "Resource": [
                "arn:aws:ec2:*:*:volume/*",
                "arn:aws:ec2:*:*:snapshot/*"
            ]
        },
        {
            "Sid": "VisualEditor10",
            "Effect": "Allow",
            "Action": [
                "sns:Publish",
                "lambda:InvokeFunction",
                "ssm:GetParameter"
            ],
            "Resource": [
                "arn:aws:lambda:*:*:function:Automation*",
                "arn:aws:sns:*:*:Automation*",
                "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetRepositoryPolicy",
                "ecr:DescribeRepositories",
                "ecr:ListImages",
                "ecr:DescribeImages",
                "ecr:BatchGetImage",
                "ecr:GetLifecyclePolicy",
                "ecr:GetLifecyclePolicyPreview",
                "ecr:ListTagsForResource",
                "ecr:DescribeImageScanFindings"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor11",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "cloudwatch:PutMetricData",
                "ec2:DescribeVolumesModifications",
                "ec2:CreateImage",
                "ec2:CopyImage",
                "ssm:ListInstanceAssociations",
                "ec2:DescribeSnapshots",
                "ssm:GetParameter",
                "ssm:UpdateAssociationStatus",
                "logs:CreateLogStream",
                "cloudformation:DescribeStackEvents",
                "ec2:StartInstances",
                "ssm:UpdateInstanceInformation",
                "ec2:DescribeVolumes",
                "cloudformation:UpdateStack",
                "ec2:UnassignPrivateIpAddresses",
                "ec2:DescribeRouteTables",
                "ssm:PutComplianceItems",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetLifecyclePolicy",
                "ec2:DetachVolume",
                "sns:*",
                "ec2:ModifyVolume",
                "ecr:DescribeImageScanFindings",
                "ec2:CreateTags",
                "ec2:ModifyNetworkInterfaceAttribute",
                "ecr:GetDownloadUrlForLayer",
                "ec2:DeleteNetworkInterface",
                "ec2messages:AcknowledgeMessage",
                "ec2:RunInstances",
                "ecr:GetAuthorizationToken",
                "ssm:GetParameters",
                "ec2:StopInstances",
                "s3-object-lambda:*",
                "ec2:AssignPrivateIpAddresses",
                "logs:CreateLogGroup",
                "cloudformation:DescribeStacks",
                "ec2:CreateNetworkInterface",
                "cloudformation:DeleteStack",
                "ec2:DescribeInstanceTypes",
                "ecr:BatchGetImage",
                "ecr:DescribeImages",
                "ec2messages:SendReply",
                "eks:DescribeCluster",
                "ec2:DescribeSubnets",
                "ec2:AttachVolume",
                "ec2:DeregisterImage",
                "ec2:DeleteSnapshot",
                "ssm:DescribeDocument",
                "ec2:DeleteTags",
                "ec2messages:GetEndpoint",
                "logs:DescribeLogStreams",
                "ssmmessages:OpenControlChannel",
                "ec2messages:GetMessages",
                "ecr:ListTagsForResource",
                "ssm:PutConfigurePackageResult",
                "ecr:ListImages",
                "ssm:GetManifest",
                "ec2messages:DeleteMessage",
                "ec2:DescribeNetworkInterfaces",
                "ec2messages:FailMessage",
                "ec2:DescribeAvailabilityZones",
                "ssmmessages:OpenDataChannel",
                "ec2:CreateSnapshot",
                "ssm:GetDocument",
                "ecr:DescribeRepositories",
                "ec2:DescribeInstanceStatus",
                "ssm:DescribeAssociation",
                "ec2:TerminateInstances",
                "ec2:DetachNetworkInterface",
                "logs:DescribeLogGroups",
                "ssm:GetDeployablePatchSnapshotForInstance",
                "s3:*",
                "ec2:DescribeTags",
                "ecr:GetLifecyclePolicyPreview",
                "ssmmessages:CreateControlChannel",
                "logs:PutLogEvents",
                "ec2:DescribeSecurityGroups",
                "ssmmessages:CreateDataChannel",
                "ec2:DescribeImages",
                "ssm:PutInventory",
                "cloudformation:CreateStack",
                "ec2:DescribeVpcs",
                "ssm:*",
                "ec2:AttachNetworkInterface",
                "ssm:ListAssociations",
                "ssm:UpdateInstanceAssociationStatus",
                "ecr:GetRepositoryPolicy"
            ],
            "Resource": "*"
        },
        {
			"Sid": "StepFunctionActions",
			"Effect": "Allow",
			"Action": [
				"states:DescribeActivity",
				"states:DescribeExecution",
				"states:DescribeMapRun",
				"states:DescribeStateMachine",
				"states:DescribeStateMachineAlias",
				"states:DescribeStateMachineForExecution",
				"states:GetExecutionHistory",
				"states:RevealSecrets",
				"states:ValidateStateMachineDefinition",
				"states:StartExecution",
				"states:StartSyncExecution"
			],
			"Resource": [
				"*"
			]
		}
    ]
}
EOF
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.34"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version
  
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
      configuration_values = jsonencode({
         defaultStorageClass = {
           enabled = true
         }
    })
    }
    aws-efs-csi-driver = {
      most_recent = true
    }
  }

  subnet_ids = data.aws_subnets.private_application_subnets.ids

  vpc_id = data.aws_vpc.application_vpc.id

  enable_cluster_creator_admin_permissions = true
  create_cluster_security_group         = true
  create_node_security_group            = true
  #cluster_additional_security_group_ids = [aws_security_group.mc_ingress_sg.id]
  create_iam_role                       = false
  enable_irsa                           = true
  iam_role_arn                          = aws_iam_role.cluster_iam_role.arn
  #node_security_group_id = data.aws_ssm_parameter.node_sg.value

  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
    iam_role_arn   = aws_iam_role.cluster_iam_role.arn
    iam_role_additional_policies = { AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy" }
  }

  eks_managed_node_groups = local.mergednodegroups

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  tags                            = var.default_tags
}

resource "aws_launch_template" "node_group_launch_template" {
  image_id = local.ami
  name     = "eks-${local.cluster_name}-nodeGroup-launchTemplate"
  user_data = base64encode(<<EOT
---
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: ${module.eks.cluster_name}
    apiServerEndpoint: ${module.eks.cluster_endpoint}
    certificateAuthority: ${module.eks.cluster_certificate_authority_data}
    cidr: ${module.eks.cluster_service_cidr}
  EOT
  )
  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name      = "${local.cluster_name} Node Group Node"
      Component = "EKS EC2 Instance"
      Stack     = "EKS EC2 Instance"
    })
  }
}

resource "aws_security_group" "mc_ingress_sg" {
  name        = "${var.project}-${var.venue}-mc-ingress-sg"
  description = "SecurityGroup for management console ingress"
  vpc_id      = data.aws_vpc.application_vpc.id
}

# TODO: select default node group more intelligently, or remove concept altogether
resource "aws_ssm_parameter" "node_group_default_launch_template_name" {
  name  = "/podaac/extensions/eks/${local.cluster_name}/nodeGroups/default/launchTemplateName"
  type  = "String"
  value = aws_launch_template.node_group_launch_template.name
}

resource "aws_ssm_parameter" "node_group_default_name" {
  name = "/podaac/extensions/eks/${var.deployment_name}/nodeGroups/default/name"
  type = "String"
  # Get name of first nodegroup in nodegroup map variable
  value = keys(var.nodegroups)[0]
  # Get first nodegroup name from keys of node group variable and use it to
  # value = split(":", aws_eks_node_group.node_groups[keys(var.node_groups)[0]].id)[0]
}

resource "helm_release" "aws-load-balancer-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.6.1"
  namespace  = "kube-system"
  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "enableWaf"
    value = "false"
  }
  set {
    name  = "enableWafv2"
    value = "false"
  }

  depends_on = [module.eks.eks_managed_node_groups]
}

resource "kubernetes_service_account" "aws-load-balancer-controller-service-account" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" : aws_iam_role.aws-load-balancer-controller-role.arn
    }
    labels = {
      "app.kubernetes.io/component" : "controller"
      "app.kubernetes.io/name" : "aws-load-balancer-controller"
    }
  }
}

# AwsLoadBalancerController Role and Policy from https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
resource "aws_iam_role" "aws-load-balancer-controller-role" {
  name = "AwsLoadBalancerControllerRole-${local.cluster_name}"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.openidc_provider_domain_name}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${local.openidc_provider_domain_name}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller",
            "${local.openidc_provider_domain_name}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  managed_policy_arns  = [aws_iam_policy.aws-load-balancer-controller-policy.arn]
  permissions_boundary = data.aws_iam_policy.permissions_boundary.id
}

resource "aws_iam_role_policy_attachment" "aws-load-balancer-policy-attachment" {
  role       = aws_iam_role.aws-load-balancer-controller-role.name
  policy_arn = data.aws_iam_policy.aws-managed-load-balancer-policy.arn
}

resource "aws_iam_policy" "aws-load-balancer-controller-policy" {
  name = "AwsLoadBalancerControllerPolicy-${local.cluster_name}"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:CreateServiceLinkedRole"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "iam:AWSServiceName" : "elasticloadbalancing.amazonaws.com"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateSecurityGroup"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateTags"
        ],
        "Resource" : "arn:aws:ec2:*:*:security-group/*",
        "Condition" : {
          "StringEquals" : {
            "ec2:CreateAction" : "CreateSecurityGroup"
          },
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ],
        "Resource" : "arn:aws:ec2:*:*:security-group/*",
        "Condition" : {
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "true",
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup"
        ],
        "Resource" : "*",
        "Condition" : {
          "Null" : {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup"
        ],
        "Resource" : "*",
        "Condition" : {
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ],
        "Resource" : [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ],
        "Condition" : {
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "true",
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ],
        "Resource" : [
          "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup"
        ],
        "Resource" : "*",
        "Condition" : {
          "Null" : {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:AddTags"
        ],
        "Resource" : [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "elasticloadbalancing:CreateAction" : [
              "CreateTargetGroup",
              "CreateLoadBalancer"
            ]
          },
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ],
        "Resource" : "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:ModifyRule"
        ],
        "Resource" : "*"
      }
    ]
  })
}


### EFS
resource "aws_kms_key" "efs_key" {
  description             = "KMS key for EFS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name      = format(local.resource_name_prefix, "EfsKmsKey")
    Component = "airflow"
    Stack     = "airflow"
  })
}

resource "aws_kms_alias" "efs_key_alias" {
  name          = "alias/${format(local.resource_name_prefix, "efs-key")}"
  target_key_id = aws_kms_key.efs_key.key_id
}

resource "aws_efs_file_system" "efs" {
  creation_token = format(local.resource_name_prefix, "AirflowEfs")
  encrypted      = true
  kms_key_id     = aws_kms_key.efs_key.arn

  tags = merge(local.common_tags, {
    Name      = format(local.resource_name_prefix, "AirflowEfs")
    Component = "airflow"
    Stack     = "airflow"
  })
}

resource "null_resource" "eks_post_deployment_actions" {
  depends_on = [module.eks]
  provisioner "local-exec" {
    command = "${path.root}/scripts/eks_post_deployment_actions.sh ${var.aws_region} ${local.cluster_name}"
  }
}

# add extra policies as inline policy
resource "aws_iam_role_policy" "sps_airflow_eks_inline_policy" {
  name   = format(local.resource_name_prefix, "EksInlinePolicy")
  role   = aws_iam_role.cluster_iam_role.id
  policy = <<EOT
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:Describe*",
                "elasticloadbalancing:ConfigureHealthCheck",
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:DeregisterTargets",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:CreateSecurityGroup",
                "ec2:Describe*",
                "ec2:RevokeSecurityGroupIngress"
            ],
            "Resource": "*"
        }
    ]
  }
  EOT
}

resource "aws_ssm_parameter" "cluster-sg" {
  type = "String"
  name = format(local.resource_name_prefix, "-eks-node-sg")
  value = module.eks.cluster_primary_security_group_id
}


