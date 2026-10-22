resource "aws_s3_object" "database_bootstrap_script" {
  bucket = "fiap-tfstate-456687462806"
  key    = "fiap/bootstrap/bootstrap_databases.py"
  source = "${path.module}/bootstrap_databases.py"
  etag   = filemd5("${path.module}/bootstrap_databases.py")
}

resource "aws_security_group" "database_bootstrap" {
  name        = "fiap-database-bootstrap"
  description = "Temporary CodeBuild access to private RDS"
  vpc_id      = data.terraform_remote_state.platform.outputs.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "secrets_manager_from_database_bootstrap" {
  security_group_id            = data.terraform_remote_state.platform.outputs.secrets_manager_endpoint_security_group_id
  referenced_security_group_id = aws_security_group.database_bootstrap.id
  description                  = "HTTPS to Secrets Manager from database bootstrap CodeBuild"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

# O CodeBuild privado precisa de HTTPS via NAT para instalar o cliente PostgreSQL
# e consultar a AWS. A regra permite apenas TCP/443; o projeto nao tem ingress.
#trivy:ignore:AWS-0104
resource "aws_vpc_security_group_egress_rule" "database_bootstrap_https" {
  security_group_id = aws_security_group.database_bootstrap.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "database_bootstrap_postgres" {
  security_group_id            = aws_security_group.database_bootstrap.id
  referenced_security_group_id = aws_security_group.postgres.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "from_database_bootstrap" {
  security_group_id            = aws_security_group.postgres.id
  referenced_security_group_id = aws_security_group.database_bootstrap.id
  description                  = "PostgreSQL bootstrap from private CodeBuild"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_cloudwatch_log_group" "database_bootstrap" {
  name              = "/aws/codebuild/fiap-database-bootstrap"
  retention_in_days = 7
}

resource "aws_iam_role" "database_bootstrap" {
  name = "fiap-database-bootstrap"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "database_bootstrap" {
  name = "fiap-database-bootstrap"
  role = aws_iam_role.database_bootstrap.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "ec2:CreateNetworkInterfacePermission"
        Resource = "arn:aws:ec2:sa-east-1:456687462806:network-interface/*"
        Condition = {
          StringEquals = { "ec2:AuthorizedService" = "codebuild.amazonaws.com" }
          ArnEquals    = { "ec2:Subnet" = [for id in data.terraform_remote_state.platform.outputs.private_subnet_ids : "arn:aws:ec2:sa-east-1:456687462806:subnet/${id}"] }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.database_bootstrap.arn}:*"
      },
      {
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::fiap-tfstate-456687462806/${aws_s3_object.database_bootstrap_script.key}"
      },
      {
        Effect = "Allow"
        Action = "secretsmanager:GetSecretValue"
        Resource = [
          aws_db_instance.postgres.master_user_secret[0].secret_arn,
          "arn:aws:secretsmanager:sa-east-1:456687462806:secret:fiap/*/postgres-*",
          "arn:aws:secretsmanager:sa-east-1:456687462806:secret:fiap/*/application-*",
          "arn:aws:secretsmanager:sa-east-1:456687462806:secret:fiap/*/admin-*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:CreateSecret", "secretsmanager:TagResource", "secretsmanager:GetRandomPassword"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:PutSecretValue"]
        Resource = "arn:aws:secretsmanager:sa-east-1:456687462806:secret:fiap/*/postgres-*"
      }
    ]
  })
}

resource "aws_codebuild_project" "database_bootstrap" {
  name         = "fiap-database-bootstrap"
  description  = "Create isolated databases and credentials inside the VPC"
  service_role = aws_iam_role.database_bootstrap.arn

  artifacts { type = "NO_ARTIFACTS" }
  source {
    type = "NO_SOURCE"
    buildspec = yamlencode({
      version = "0.2"
      phases = {
        install = { commands = ["python -m pip install --quiet boto3 psycopg2-binary bcrypt"] }
        build = { commands = [
          "aws s3 cp s3://fiap-tfstate-456687462806/${aws_s3_object.database_bootstrap_script.key} /tmp/bootstrap_databases.py",
          "python /tmp/bootstrap_databases.py"
        ] }
      }
    })
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "DB_HOST"
      value = aws_db_instance.postgres.address
    }
    environment_variable {
      name  = "MASTER_SECRET_ARN"
      value = aws_db_instance.postgres.master_user_secret[0].secret_arn
    }
  }

  vpc_config {
    vpc_id             = data.terraform_remote_state.platform.outputs.vpc_id
    subnets            = data.terraform_remote_state.platform.outputs.private_subnet_ids
    security_group_ids = [aws_security_group.database_bootstrap.id]
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.database_bootstrap.name
    }
  }

  depends_on = [aws_iam_role_policy.database_bootstrap, aws_vpc_security_group_egress_rule.database_bootstrap_https, aws_vpc_security_group_egress_rule.database_bootstrap_postgres]
}
