variable "region" {
  type    = string
  default = "sa-east-1"
}

variable "environment" {
  type        = string
  description = "Identificador do ambiente do banco."

  validation {
    condition     = contains(["shared", "develop", "homol", "prod"], var.environment)
    error_message = "Use shared, develop, homol ou prod."
  }
}

variable "platform_state_key" {
  type        = string
  description = "Chave do estado Terraform da plataforma EKS correspondente."
}

variable "db_name" {
  type    = string
  default = "oficina_db"
}

variable "db_username" {
  type    = string
  default = "oficina"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "multi_az" {
  type    = bool
  default = false
}
