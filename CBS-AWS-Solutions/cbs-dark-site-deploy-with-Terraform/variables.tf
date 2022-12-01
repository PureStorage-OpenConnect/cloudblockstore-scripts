variable "aws_ami_owner" {
  type = list(any)
}
variable "aws_ami_name" {
  type = list(any)
}
variable "aws_ami_architecture" {
  type = list(any)
}
variable "aws_instance_type" {
  type = string
}
variable "aws_key_name" {
  type = string
}
variable "aws_user_data" {
  type = string
}
variable "aws_access_key" {
  type = string
}
variable "aws_secret_key" {
  type = string
}
variable "aws_region" {
  type = string
}
variable "aws_zone" {
  type = string
}
variable "aws_prefix" {
  type = string
}
variable "template_url" {
  type = string
}
variable "log_sender_domain" {
  type = string
}
variable "alert_recipients" {
  type = list(string)
}
variable "purity_instance_type" {
  type = string
}
variable "license_key" {
  type = string
}

variable "tag_key" {
  type = string
}
variable "tag_value" {
  type = string
}