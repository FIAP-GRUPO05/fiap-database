variable "region" {
  type        = string
  default     = "us-east-1"
  description = "Região onde o cluster EKS foi criado"
}
variable "clusterName" {
  type        = string
  default     = "my-cluster"
  description = "Nome do cluster EKS criado pelo repositório fiap-k8s"
}
variable "postgresDb" {
  type        = string
  default     = "oficina_db"
  description = "Nome do banco de dados"
}
variable "postgresUser" {
  type        = string
  default     = "oficina"
  description = "Usuário do banco de dados"
}
variable "postgresPassword" {
  type        = string
  sensitive   = true
  description = "Senha do banco de dados. Deve ser a mesma do postgresPassword do fiap-k8s, usada no api-secret"
}
variable "projectName" {
  type        = string
  default     = "TC-FIAP"
  description = "Nome do projeto, usado como prefixo dos recursos do RDS"
}
variable "vpcName" {
  type        = string
  default     = "main-vpc"
  description = "Tag Name da VPC criada pelo repositório fiap-k8s"
}
variable "postgresVersion" {
  type        = string
  default     = "15"
  description = "Versão major do PostgreSQL no RDS"
}
variable "dbInstanceClass" {
  type        = string
  default     = "db.t3.micro"
  description = "Classe da instância do RDS"
}
variable "dbAllocatedStorage" {
  type        = number
  default     = 20
  description = "Armazenamento do RDS em GB"
}
