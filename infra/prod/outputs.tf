#
# output "rds_endpoint" {
#   value       = aws_db_instance.postgres.endpoint
#   description = "Endpoint do RDS (host:porta). Dentro do cluster a API usa postgres-service:5432"
# }

# Hostname do Load Balancer interno do Postgres. E o valor que alimenta a variavel
# ----> db_host do fiap-lambda. Vazio logo apos o primeiro apply: o ELB leva alguns minutos.
data "kubernetes_service" "postgres_internal" {
  depends_on = [kubectl_manifest.postgres-internal-service]

  metadata {
    name      = "postgres-internal"
    namespace = "prod"
  }
}

output "db_host" {
  value       = try(data.kubernetes_service.postgres_internal.status[0].load_balancer[0].ingress[0].hostname, "")
  description = "Valor pronto para colar em db_host no terraform.tfvars do fiap-lambda."
}
