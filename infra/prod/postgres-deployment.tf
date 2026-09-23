# Substituído pelo RDS (rds.tf). Mantido comentado como referência do Postgres em pod.
#
# resource "kubectl_manifest" "postgres-deployment" {
#   depends_on = [kubectl_manifest.postgres-secret]
#   yaml_body  = <<YAML
# apiVersion: apps/v1
# kind: Deployment
# metadata:
#   name: postgres-deployment
#   namespace: prod
# spec:
#   replicas: 1
#   selector:
#     matchLabels:
#       app: postgres
#   template:
#     metadata:
#       labels:
#         app: postgres
#     spec:
#       containers:
#       - name: postgres
#         image: postgres:15-alpine
#         ports:
#         - containerPort: 5432
#         envFrom:
#         - secretRef:
#             name: postgres-secret
# YAML
# }