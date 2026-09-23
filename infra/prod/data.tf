data "aws_eks_cluster" "cluster" {
  name = var.clusterName
}

data "aws_eks_cluster_auth" "auth" {
  name = var.clusterName
}
