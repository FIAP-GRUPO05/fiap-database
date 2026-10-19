# RDS privado compartilhado

Raiz ativa para a conta TWM `456687462806`, em `sa-east-1`. Estado remoto:
`fiap/database-shared.tfstate`. O RDS PostgreSQL usa `db.t4g.micro`, armazenamento
gp3 criptografado, backups de sete dias e protecao contra exclusao. Nao e publico.

Tres bancos (`oficina_develop`, `oficina_homol`, `oficina_prod`) e usuarios distintos
preservam o isolamento de credenciais. A instancia e compartilhada para reduzir
custo; nao oferece o isolamento ou a disponibilidade de tres instancias Multi-AZ.
Somente EKS, Lambda e o executor privado podem acessar a porta 5432.

## Aplicar e verificar

```powershell
$env:AWS_PROFILE = '<perfil-administrador>'
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
aws codebuild start-build --project-name fiap-database-bootstrap
```

O CodeBuild cria bancos, usuarios e segredos sem expor senhas. Use o ID retornado
com `python ../../.github/scripts/wait_codebuild.py <id>` para aguardar o resultado.
As migracoes de tabelas continuam no Flyway da aplicacao. Execute o bootstrap
novamente apos o primeiro deploy para criar o administrador de cada ambiente.

Segredos: `fiap/<ambiente>/postgres`, `fiap/<ambiente>/application` e
`fiap/<ambiente>/admin`. O bootstrap preserva os valores existentes. A senha do
administrador so aparece no Secrets Manager para operadores autorizados; no banco
fica somente o hash bcrypt. Nao e preciso que cada integrante configure senhas.

Em develop/homol, os CPFs sinteticos `52998224725` (ACTIVE) e `11144477735`
(INACTIVE) permitem executar os testes externos da Lambda. Nao sao criados em
prod e registros existentes nao sao sobrescritos. As definicoes em `infra/prod`
documentam o laboratorio anterior e nao devem ser aplicadas na conta TWM.

O workflow valida Terraform e seguranca. Depois de merges em branches protegidas,
OIDC permite somente iniciar/acompanhar o bootstrap, que comprova a conexao TLS e
os bancos dentro da VPC. Alteracoes estruturais do RDS ainda exigem o plano e o
apply administrativo acima; o workflow nao possui permissao de destruir o banco.
