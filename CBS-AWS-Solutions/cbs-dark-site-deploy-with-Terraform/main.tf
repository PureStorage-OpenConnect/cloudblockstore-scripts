terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    cbs = {
      source = "PureStorage-OpenConnect/cbs"
    }
  }
}
provider "cbs" {
  aws {
    region = var.aws_region
  }
}
provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
resource "aws_vpc" "cbs_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = format("%s%s%s", var.aws_prefix, var.aws_region, "-vpc")
  }
}
resource "aws_subnet" "sys" {
  vpc_id            = aws_vpc.cbs_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = format("%s%s", var.aws_region, var.aws_zone)
  tags = {
    Name = format("%s%s%s", var.aws_prefix, var.aws_region, "-sys-subnet")
  }
}
resource "aws_subnet" "mgmt" {
  vpc_id            = aws_vpc.cbs_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = format("%s%s", var.aws_region, var.aws_zone)
  tags = {
    Name = format("%s%s%s", var.aws_prefix, var.aws_region, "-mgmt-subnet")
  }
}
resource "aws_subnet" "repl" {
  vpc_id            = aws_vpc.cbs_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = format("%s%s", var.aws_region, var.aws_zone)
  tags = {
    Name = format("%s%s%s", var.aws_prefix, var.aws_region, "-repl-subnet")
  }
}
resource "aws_subnet" "iscsi" {
  vpc_id            = aws_vpc.cbs_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = format("%s%s", var.aws_region, var.aws_zone)
  tags = {
    Name = format("%s%s%s", var.aws_prefix, var.aws_region, "-iscsi-subnet")
  }
}
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.cbs_vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = format("%s%s", var.aws_region, var.aws_zone)
  tags = {
    Name = format("%s%s%s", var.aws_prefix, var.aws_region, "-public-subnet")
  }
}
resource "aws_vpc_endpoint" "s3" {
  vpc_id          = aws_vpc.cbs_vpc.id
  service_name    = format("%s%s%s", "com.amazonaws.", var.aws_region, ".s3")
  route_table_ids = [aws_route_table.cbs_routetable.id]
  tags = {
    Name = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-s3endpoint")
  }
}
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id          = aws_vpc.cbs_vpc.id
  service_name    = format("%s%s%s", "com.amazonaws.", var.aws_region, ".dynamodb")
  route_table_ids = [aws_route_table.cbs_routetable.id]
  tags = {
    Name = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-dynamodbendpoint")
  }
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = aws_vpc.cbs_vpc.id
  service_name        = format("%s%s%s", "com.amazonaws.", var.aws_region, ".ec2")
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.sys.id]
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.cbs_vpc_endpoint.id,
  ]
  tags = {
    Name = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-ec2endpoint")
  }
}

resource "aws_vpc_endpoint" "autoscaling" {
  vpc_id              = aws_vpc.cbs_vpc.id
  service_name        = format("%s%s%s", "com.amazonaws.", var.aws_region, ".autoscaling")
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.sys.id]
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.cbs_vpc_endpoint.id,
  ]
  tags = {
    Name = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-autoscalingendpoint")
  }
}

resource "aws_vpc_endpoint" "cloudformation" {
  vpc_id              = aws_vpc.cbs_vpc.id
  service_name        = format("%s%s%s", "com.amazonaws.", var.aws_region, ".cloudformation")
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.sys.id]
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.cbs_vpc_endpoint.id,
  ]
  tags = {
    Name = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-cloudformationendpoint")
  }
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id              = aws_vpc.cbs_vpc.id
  service_name        = format("%s%s%s", "com.amazonaws.", var.aws_region, ".kms")
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.sys.id]
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.cbs_vpc_endpoint.id,
  ]
  tags = {
    Name = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-kmsendpoint")
  }
}


resource "aws_vpc_endpoint" "sts" {
  vpc_id              = aws_vpc.cbs_vpc.id
  service_name        = format("%s%s%s", "com.amazonaws.", var.aws_region, ".sts")
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.sys.id]
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.cbs_vpc_endpoint.id,
  ]
  tags = {
    Name = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-stsendpoint")
  }
}



resource "aws_vpc_endpoint" "s3-global" {
  vpc_id              = aws_vpc.cbs_vpc.id
  service_name        = "com.amazonaws.s3-global.accesspoint"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.sys.id]
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.cbs_vpc_endpoint.id,
  ]
  tags = {
    Name = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-s3-global-endpoint")
  }
}

resource "aws_internet_gateway" "cbs_internet_gateway" {
  vpc_id = aws_vpc.cbs_vpc.id
  tags = {
    Name = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-internet-gateway")
  }
}

# resource "aws_eip" "cbs_nat_gateway_eip" {
#   vpc = true
#   tags = {
#     Name = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-internet-gateway-eip")
#   }
# }
# resource "aws_nat_gateway" "cbs_nat_gateway" {
#   allocation_id = aws_eip.cbs_nat_gateway_eip.id
#   subnet_id     = aws_subnet.public.id
#   tags = {
#     Name = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-nat-gateway")
#   }

#   # To ensure proper ordering, it is recommended to add an explicit dependency
#   # on the Internet Gateway for the VPC.
#   depends_on = [aws_internet_gateway.cbs_internet_gateway]
# }

resource "aws_security_group" "cbs_repl" {
  name        = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-repl-securitygroup")
  description = "Replication Network Traffic"
  vpc_id      = aws_vpc.cbs_vpc.id

  ingress {
    description = "repl"
    from_port   = 8117
    to_port     = 8117
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "repl"
    from_port   = 8117
    to_port     = 8117
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-repl-securitygroup")
  }
}
resource "aws_security_group" "cbs_iscsi" {
  name        = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-iscsi-securitygroup")
  description = "ISCSI Network Traffic"
  vpc_id      = aws_vpc.cbs_vpc.id

  ingress {
    description = "iscsi"
    from_port   = 3260
    to_port     = 3260
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "iscsi"
    from_port   = 3260
    to_port     = 3260
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-iscsi-securitygroup")
  }
}
resource "aws_security_group" "cbs_mgmt" {
  name        = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-mgmt-securitygroup")
  description = "Management Network Traffic"
  vpc_id      = aws_vpc.cbs_vpc.id

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "array"
    from_port   = 8084
    to_port     = 8084
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }



  egress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "syslog"
    from_port   = 514
    to_port     = 514
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-mgmt-securitygroup")
  }
}

resource "aws_security_group" "cbs_public" {
  name        = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-public-securitygroup")
  description = "Allow Network Traffic to JumpHost"
  vpc_id      = aws_vpc.cbs_vpc.id

  ingress {
    description = "iSCSI"
    from_port   = 3260
    to_port     = 3260
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    description = "SYSLOG"
    from_port   = 514
    to_port     = 514
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-public-securitygroup")
  }
}

resource "aws_security_group" "cbs_vpc_endpoint" {
  name        = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-vpcendpoint-securitygroup")
  description = "VPC Endpoint Network Traffic"
  vpc_id      = aws_vpc.cbs_vpc.id

  ingress {
    description = "vpc endpoint"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-vpcendpoint-securitygroup")
  }
}

resource "aws_route_table" "cbs_routetable" {
  vpc_id = aws_vpc.cbs_vpc.id

  tags = {
    Name = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-routetable")
  }
}
resource "aws_route_table_association" "sys" {
  subnet_id      = aws_subnet.sys.id
  route_table_id = aws_route_table.cbs_routetable.id
}
resource "aws_route_table_association" "mgmt" {
  subnet_id      = aws_subnet.mgmt.id
  route_table_id = aws_route_table.cbs_routetable_public.id
}

resource "aws_route_table" "cbs_routetable_public" {
  vpc_id = aws_vpc.cbs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cbs_internet_gateway.id
  }

  tags = {
    Name = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-routetable-public")
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.cbs_routetable_public.id
}

# resource "aws_route_table" "cbs_routetable_main" {
#   vpc_id = aws_vpc.cbs_vpc.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_nat_gateway.cbs_nat_gateway.id
#   }

#   tags = {
#     Name = format("%s%s", aws_vpc.cbs_vpc.tags.Name, "-routetable-main")
#   }
# }

# resource "aws_main_route_table_association" "main" {
#   vpc_id         = aws_vpc.cbs_vpc.id
#   route_table_id = aws_route_table.cbs_routetable_main.id
# }
resource "aws_iam_role" "cbs_role" {
  name = format("%s%s%s", var.aws_prefix, var.aws_region, "-cbs-iamrole")

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "cloudformation.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_role_policy" "cbs_role_policy" {
  name = format("%s%s%s", var.aws_prefix, var.aws_region, "-cbs-iamrolepolicy")
  role = aws_iam_role.cbs_role.id
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "application-autoscaling:DeleteScalingPolicy",
          "application-autoscaling:DeregisterScalableTarget",
          "application-autoscaling:DescribeScalableTargets",
          "application-autoscaling:DescribeScalingPolicies",
          "application-autoscaling:DescribeScheduledActions",
          "application-autoscaling:PutScalingPolicy",
          "application-autoscaling:RegisterScalableTarget",
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:CreateLaunchConfiguration",
          "autoscaling:CreateOrUpdateTags",
          "autoscaling:DeleteAutoScalingGroup",
          "autoscaling:DeleteLaunchConfiguration",
          "autoscaling:DeleteTags",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "autoscaling:PutLifecycleHook",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "autoscaling:UpdateAutoScalingGroup",
          "dynamodb:CreateTable",
          "dynamodb:DeleteTable",
          "dynamodb:DescribeTable",
          "dynamodb:ListTables",
          "dynamodb:ListTagsOfResource",
          "dynamodb:TagResource",
          "dynamodb:UntagResource",
          "dynamodb:UpdateTable",
          "ec2:AttachNetworkInterface",
          "ec2:AttachVolume",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CreateNetworkInterface",
          "ec2:CreatePlacementGroup",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateLaunchTemplateVersion",
          "ec2:DeleteLaunchTemplate",
          "ec2:DeleteNetworkInterface",
          "ec2:DeletePlacementGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteTags",
          "ec2:DeleteVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribePlacementGroups",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications",
          "ec2:DescribeVpcs",
          "ec2:DetachNetworkInterface",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:ModifyVolumeAttribute",
          "ec2:ModifyInstanceAttribute",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RunInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances",
          "iam:AddRoleToInstanceProfile",
          "iam:AttachRolePolicy",
          "iam:CreateInstanceProfile",
          "iam:CreatePolicy",
          "iam:CreateRole",
          "iam:CreateServiceLinkedRole",
          "iam:DeleteInstanceProfile",
          "iam:DeletePolicy",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:DetachRolePolicy",
          "iam:GetInstanceProfile",
          "iam:GetPolicy",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRoleTags",
          "iam:PassRole",
          "iam:PutRolePolicy",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:SimulatePrincipalPolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "kms:CreateAlias",
          "kms:CreateKey",
          "kms:DeleteAlias",
          "kms:DescribeKey",
          "kms:DisableKey",
          "kms:EnableKey",
          "kms:ListAliases",
          "kms:ListKeyPolicies",
          "kms:ListKeys",
          "kms:ListResourceTags",
          "kms:PutKeyPolicy",
          "kms:ScheduleKeyDeletion",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:UpdateAlias",
          "lambda:CreateFunction",
          "lambda:DeleteFunction",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:InvokeFunction",
          "lambda:ListTags",
          "lambda:TagResource",
          "lambda:UntagResource",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:DeleteBucketPolicy",
          "s3:GetBucketPolicy",
          "s3:GetBucketTagging",
          "s3:ListBucket",
          "s3:PutBucketPolicy",
          "s3:PutBucketTagging",
          "s3:PutBucketVersioning",
          "s3:PutMetricsConfiguration",
          "sts:assumerole"
        ],
        "Resource" : "*"
      }
    ]
  })
}

data "aws_ami" "linux" {
  owners      = var.aws_ami_owner
  most_recent = true
  filter {
    name   = "name"
    values = var.aws_ami_name
  }
  filter {
    name   = "architecture"
    values = var.aws_ami_architecture
  }
}

resource "aws_instance" "linux" {
  ami                    = data.aws_ami.linux.image_id
  instance_type          = var.aws_instance_type
  vpc_security_group_ids = [aws_security_group.cbs_public.id]
  subnet_id              = aws_subnet.mgmt.id
  key_name               = var.aws_key_name
  tags = {
    Name = format("%s%s%s", var.aws_prefix, var.aws_region, "-jumpbox")
  }
  user_data                   = var.aws_user_data
  associate_public_ip_address = true
}


resource "cbs_array_aws" "cbs_aws" {

  array_name = format("%s%s%s", var.aws_prefix, var.aws_region, "-cbs")

  deployment_template_url = var.template_url
  deployment_role_arn     = aws_iam_role.cbs_role.arn

  log_sender_domain = var.log_sender_domain
  alert_recipients  = var.alert_recipients
  array_model       = var.purity_instance_type
  license_key       = var.license_key

  pureuser_key_pair_name = var.aws_key_name

  system_subnet      = aws_subnet.sys.id
  replication_subnet = aws_subnet.repl.id
  iscsi_subnet       = aws_subnet.iscsi.id
  management_subnet  = aws_subnet.mgmt.id

  replication_security_group = aws_security_group.cbs_repl.id
  iscsi_security_group       = aws_security_group.cbs_iscsi.id
  management_security_group  = aws_security_group.cbs_mgmt.id
  tags = {
    "var.tag_key" = var.tag_value
  }
  depends_on = [
    aws_instance.linux,
    aws_internet_gateway.cbs_internet_gateway,
    aws_iam_role.cbs_role,
    aws_iam_role_policy.cbs_role_policy,
    aws_security_group.cbs_iscsi,
    aws_security_group.cbs_mgmt,
    aws_security_group.cbs_repl,
    aws_subnet.iscsi,
    aws_subnet.mgmt,
    aws_subnet.repl,
    aws_subnet.sys,
    aws_vpc.cbs_vpc,
    aws_route_table_association.public,
    aws_vpc_endpoint.s3,
    aws_vpc_endpoint.dynamodb,
    aws_vpc_endpoint.ec2,
    aws_vpc_endpoint.kms,
    aws_vpc_endpoint.cloudformation,
    aws_vpc_endpoint.autoscaling,
    aws_vpc_endpoint.sts
  ]
}


# Outputs for Pre-Requisites
output "vm_private_ip" {
  value = aws_instance.linux.private_ip
}
output "vm_public_ip" {
  value = aws_instance.linux.public_ip
}
output "vm_name" {
  value = aws_instance.linux.tags.Name
}

#Outputs for CBS
output "cbs_gui_endpoint" {
  value = cbs_array_aws.cbs_aws.gui_endpoint
}
output "cbs_repl_endpoint_ct0" {
  value = cbs_array_aws.cbs_aws.replication_endpoint_ct0
}
output "cbs_repl_endpoint_ct1" {
  value = cbs_array_aws.cbs_aws.replication_endpoint_ct1
}
output "cbs_iscsi_endpoint_ct0" {
  value = cbs_array_aws.cbs_aws.iscsi_endpoint_ct0
}
output "cbs_iscsi_endpoint_ct1" {
  value = cbs_array_aws.cbs_aws.iscsi_endpoint_ct1
}
