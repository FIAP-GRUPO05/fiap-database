data "terraform_remote_state" "platform" {
  backend = "s3"
  config = {
    bucket = "fiap-tfstate-456687462806"
    key    = var.platform_state_key
    region = var.region
  }
}

resource "aws_db_subnet_group" "postgres" {
  name       = "fiap-${var.environment}-postgres"
  subnet_ids = data.terraform_remote_state.platform.outputs.private_subnet_ids

  tags = { Name = "fiap-${var.environment}-postgres" }
}

resource "aws_security_group" "postgres" {
  name        = "fiap-${var.environment}-postgres"
  description = "PostgreSQL privado para a aplicacao FIAP"
  vpc_id      = data.terraform_remote_state.platform.outputs.vpc_id

  tags = { Name = "fiap-${var.environment}-postgres" }
}

resource "aws_vpc_security_group_ingress_rule" "from_eks" {
  security_group_id            = aws_security_group.postgres.id
  referenced_security_group_id = data.terraform_remote_state.platform.outputs.cluster_security_group_id
  description                  = "PostgreSQL somente a partir dos nos do EKS"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "from_lambda" {
  security_group_id            = aws_security_group.postgres.id
  referenced_security_group_id = data.terraform_remote_state.platform.outputs.lambda_security_group_id
  description                  = "PostgreSQL somente a partir da Lambda de autenticacao"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_db_instance" "postgres" {
  identifier                      = "fiap-${var.environment}-postgres"
  engine                          = "postgres"
  engine_version                  = var.engine_version
  instance_class                  = var.instance_class
  allocated_storage               = 20
  max_allocated_storage           = 100
  storage_type                    = "gp3"
  storage_encrypted               = true
  db_name                         = var.db_name
  username                        = var.db_username
  manage_master_user_password     = true
  db_subnet_group_name            = aws_db_subnet_group.postgres.name
  vpc_security_group_ids          = [aws_security_group.postgres.id]
  publicly_accessible             = false
  multi_az                        = var.multi_az
  backup_retention_period         = contains(["shared", "prod"], var.environment) ? 7 : 1
  deletion_protection             = contains(["shared", "prod"], var.environment)
  skip_final_snapshot             = !contains(["shared", "prod"], var.environment)
  final_snapshot_identifier       = contains(["shared", "prod"], var.environment) ? "fiap-${var.environment}-postgres-final" : null
  auto_minor_version_upgrade      = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = { Name = "fiap-${var.environment}-postgres" }
}
