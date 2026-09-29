
resource "kubectl_manifest" "postgres-internal-service" {
  depends_on = [kubectl_manifest.postgres-deployment]
  yaml_body  = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: postgres-internal
  namespace: prod
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-internal: "true"
spec:
  selector:
    app: postgres
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
  type: LoadBalancer

YAML
}
