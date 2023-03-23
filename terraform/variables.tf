variable "environment_suffix" {
  type        = string
  description = "The suffix to append to the environment name"
}

variable "kv_suffix" {
  type = string
  default = "-prod"
}

variable "project_name" {
  type    = string
}

variable "database_name" {
  type        = string
}

variable "database_dialect" {
  type        = string
}

variable "database_port" {
  type        = string
}

variable "access_token_expiry" {
  type        = string
}

variable "refresh_token_expiry" {
  type        = string
}

variable "refresh_token_cookie_name" {
  type        = string
}

variable "api_port" {
  type        = string
}