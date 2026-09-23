# A VPC e as subnets são criadas pelo repositório fiap-k8s; aqui elas são
# localizadas pela tag Name.
data "aws_vpc" "main" {
  tags = {
    Name = var.vpcName
  }
}

# O subnet group do RDS exige subnets em pelo menos duas AZs: a VPC tem uma em
# us-east-1a e outra em us-east-1b.
data "aws_subnets" "main" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

resource "aws_db_subnet_group" "postgres" {
  name       = "${lower(var.projectName)}-postgres"
  subnet_ids = data.aws_subnets.main.ids
}

# Libera o Postgres só para dentro da VPC, onde ficam os nós e os pods do EKS.
resource "aws_security_group" "postgres" {
  name        = "${var.projectName}-postgres-sg"
  description = "Acesso ao RDS a partir da VPC do EKS"
  vpc_id      = data.aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "postgres_from_vpc" {
  security_group_id = aws_security_group.postgres.id
  description       = "Postgres a partir da VPC"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  cidr_ipv4         = data.aws_vpc.main.cidr_block
}

resource "aws_db_instance" "postgres" {
  identifier     = "${lower(var.projectName)}-postgres"
  engine         = "postgres"
  engine_version = var.postgresVersion
  instance_class = var.dbInstanceClass

  allocated_storage = var.dbAllocatedStorage
  storage_type      = "gp3"

  db_name  = var.postgresDb
  username = var.postgresUser
  password = var.postgresPassword

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.postgres.id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = 1
  apply_immediately       = true
  deletion_protection     = false
  skip_final_snapshot     = true
}

# Mantém o nome postgres-service usado no SPRING_DATASOURCE_URL do api-secret
# (fiap-k8s), agora resolvendo para o endpoint do RDS. force_new recria o
# Service, já que o tipo ClusterIP anterior não pode virar ExternalName in-place.
resource "kubectl_manifest" "postgres-service" {
  force_new = true
  yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: prod
spec:
  type: ExternalName
  externalName: ${aws_db_instance.postgres.address}
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432

YAML
}
