variable "region" {
  type    = string
  default = "us-east-1"
}

variable "function_name" {
  description = "A unique name for your Lambda Function"
  type        = string
  default     = ""
}

variable "cbs_api_client_private_key" {
  description = "file path of the private key used to in genating the cbs api client"
  type        = string
}

variable "cbs_ip" {
  type = string
}

variable "cbs_username" {
  type = string
}

variable "cbs_api_client_id" {
  type = string
}

variable "cbs_api_key_id" {
  type = string
}

variable "cbs_api_issuer" {
  type = string
}

variable "vpc_subnet_ids" {
  description = "List of subnet ids when Lambda Function should run in the VPC. Usually private or intra subnets."
  type        = list(string)
  default     = null
}

variable "vpc_security_group_ids" {
  description = "List of security group ids when Lambda Function should run in the VPC."
  type        = list(string)
  default     = null
}



