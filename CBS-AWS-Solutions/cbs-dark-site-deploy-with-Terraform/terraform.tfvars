# See blog at https://davidstamen.com/2021/07/26/pure-cloud-block-store-on-aws-jump-start/ for more information on AWS Quick Launch

#AWS Variables
aws_prefix     = "cbs-darksite-"
aws_access_key = "000-000-000"
aws_secret_key = "000-000-000"
aws_region     = "us-east-1"
aws_zone       = "a"
aws_ami_owner  = ["amazon"]
aws_ami_name = ["amzn2*MATE*"]
aws_ami_architecture = ["x86_64"]
aws_instance_type    = "t3.micro"
aws_key_name         = "aws_keypair"
aws_user_data        = <<EOF
        #!/bin/bash
        amazon-linux-extras install epel -y
        yum install syslog-ng -y
        systemctl enable syslog-ng
        systemctl start syslog-ng       
        EOF
#CBS Variables
## Template URL for Purity version 6.3.5
template_url         = "https://s3.amazonaws.com/awsmp-fulfillment-cf-templates-prod/4ea2905b-7939-4ee0-a521-d5c2fcb41214/9d843fe5376b4a6888b85f7a6fc6a007.template"
log_sender_domain    = "xyz.com"
alert_recipients     = ["xyz@xyz.com"]
purity_instance_type = "V10AR1"
license_key          = "CBS-DARK-SITE"
tag_key = "project"
tag_value = "cbs-darksite"

