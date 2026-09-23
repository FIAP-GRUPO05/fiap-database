# Substituído pelo RDS (rds.tf). Mantido comentado como referência do Postgres em pod.
#
# resource "kubectl_manifest" "postgres-service" {
#   depends_on = [kubectl_manifest.postgres-deployment]
#   yaml_body  = <<YAML
# apiVersion: v1
# kind: Service
# metadata:
#   name: postgres-service
#   namespace: prod
# spec:
#   selector:
#     app: postgres
#   ports:
#     - protocol: TCP
#       port: 5432
#       targetPort: 5432
#   type: ClusterIP
#
# YAML
# }