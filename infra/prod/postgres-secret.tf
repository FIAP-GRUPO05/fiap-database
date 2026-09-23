# Substituído pelo RDS (rds.tf). Mantido comentado como referência do Postgres em pod.
#
# # O namespace prod é criado pelo repositório fiap-k8s.
# resource "kubectl_manifest" "postgres-secret" {
#   yaml_body = <<YAML
# apiVersion: v1
# kind: Secret
# metadata:
#   name: postgres-secret
#   namespace: prod
# type: Opaque
# stringData:
#   POSTGRES_DB: "${var.postgresDb}"
#   POSTGRES_USER: "${var.postgresUser}"
#   POSTGRES_PASSWORD: "${var.postgresPassword}"
#
# YAML
# }
