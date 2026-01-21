resource "aws_lambda_function" "ami_rotation" {
  function_name    =  format(local.resource_name_prefix, "eks_ami_rotation")
  role            = aws_iam_role.lambda_execution.arn
  handler         = "lambda_ami_updater.lambda_handler"
  runtime         = "python3.13"
  timeout         = 60

  filename = "${path.module}/lambda_ami_updater.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_ami_updater.zip")

  environment {
    variables = {
      SSM_PARAMETER_FOR_AMI = data.aws_ssm_parameter.eks_amis.name
      LAUNCH_TEMPLATE_NAME  = aws_launch_template.node_group_launch_template.name
      AUTO_SCALING_GROUP_NAME = [for asg_name in module.eks.eks_managed_node_groups_autoscaling_group_names: asg_name][0]
      SNS_TOPIC_ARN = aws_sns_topic.ami_rotation.arn
      ROTATION_PERIOD = var.ami_rotation_period
      EKS_VERSION = var.cluster_version
    }
  }
}

data "aws_iam_policy_document" "lambda_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_execution" {
  name = format(local.resource_name_prefix, "eks_ami_lambda_execution_role")

  assume_role_policy = data.aws_iam_policy_document.lambda_role.minified_json
}

data "aws_iam_policy_document" "lambda_policies" {
  statement {
    actions = ["ssm:GetParameter"]
    resources = [data.aws_ssm_parameter.eks_amis.arn]
  }

  statement {
    actions = ["autoscaling:StartInstanceRefresh"]
    resources = ["*"]
  }

  statement {
    actions = [
      "ec2:ModifyLaunchTemplate",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateLaunchTemplateVersion"
    ]
    resources = [aws_launch_template.node_group_launch_template.arn]
  }

  statement {
    actions = [
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeLaunchTemplateVersions"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:us-west-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.ami_rotation.function_name}",
      "arn:aws:logs:us-west-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.ami_rotation.function_name}:*"
    ]
  }

  statement {
    actions = ["sns:Publish"]
    resources = [aws_sns_topic.ami_rotation.arn]
  }

  statement {
    actions = ["lambda:ListTags"]
    resources = [aws_lambda_function.ami_rotation.arn]
  }
}

resource "aws_iam_policy" "lambda_execution" {
  name        = format(local.resource_name_prefix, "eks_ami_lambda_execution_policy")
  description = "Allows Lambda to read SSM and update EC2 launch templates"

  policy = data.aws_iam_policy_document.lambda_policies.minified_json
}

resource "aws_iam_role_policy_attachment" "lambda_execution" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.lambda_execution.arn
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_sns_topic" "ami_rotation" {
  name = format(local.resource_name_prefix, "eks_ami_rotation")
}

resource "aws_sns_topic_policy" "ami_rotation_policy" {
  arn    = aws_sns_topic.ami_rotation.arn
  policy = data.aws_iam_policy_document.sns_ami_rotation_policy.json
}

data "aws_iam_policy_document" "sns_ami_rotation_policy" {
  statement {
    actions = ["SNS:Publish"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.lambda_execution.arn]
    }
    resources = [aws_sns_topic.ami_rotation.arn]
  }
}

/*
resource "aws_sns_topic_subscription" "notification_emails" {
  for_each   = toset(var.notification_emails)
  topic_arn  = aws_sns_topic.ami_rotation.arn
  protocol   = "email"
  endpoint   = each.value
}
*/

resource "aws_cloudwatch_event_rule" "cron_rule" {
  #count = 1

  name                = format(local.resource_name_prefix, "cron_rule")
  description         = "Triggers every 12 hours"
  schedule_expression = "cron(0 0 ? * SUN-SAT *)"
}

resource "aws_cloudwatch_event_target" "eventbridge_to_lambda" {
  #for_each = toset(aws_cloudwatch_event_rule.cron_rule[*].name)

  rule      = aws_cloudwatch_event_rule.cron_rule.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.ami_rotation.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  #for_each = toset(aws_cloudwatch_event_rule.cron_rule[*].arn)

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ami_rotation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron_rule.arn
}

resource "aws_iam_role" "eventbridge" {
  name = format(local.resource_name_prefix, "eventbridge_ssm_role")
  assume_role_policy = data.aws_iam_policy_document.eventbridge_role.minified_json
}

data "aws_iam_policy_document" "eventbridge_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "eventbridge_lambda" {
  name = format(local.resource_name_prefix, "eventbridge_lambda_policy")
  role   = aws_iam_role.eventbridge.name
  policy = data.aws_iam_policy_document.eventbridge_lambda.minified_json
}

data "aws_iam_policy_document" "eventbridge_lambda" {
  statement {
    actions = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.ami_rotation.arn]
  }
}