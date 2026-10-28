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

variable "engine_version" {
  type        = string
  default     = "17.11"
  description = "PostgreSQL version validated with the application's Flyway 10.20.1; do not inherit a new major from AWS defaults."
  validation {
    condition     = can(regex("^17\\.[0-9]+$", var.engine_version))
    error_message = "Use PostgreSQL 17.x validated with the application before changing major versions."
  }
}
