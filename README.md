# fiap-database

Infraestrutura como código do PostgreSQL privado no Amazon RDS e do bootstrap de bancos, usuários e segredos por ambiente. As tabelas são gerenciadas pelo Flyway da aplicação.

📚 **[Documentação principal — fiap-docs](https://github.com/FIAP-GRUPO05/fiap-docs)** · [Guia do banco](https://github.com/FIAP-GRUPO05/fiap-docs/blob/main/guides/database.md)

## Requisitos

- Terraform 1.13 ou superior.
- Python 3.12 para os testes dos scripts de CI/CD.
- AWS CLI e uma identidade autorizada somente para operações administrativas na AWS.

## Validar localmente

Na raiz deste repositório:

```powershell
terraform -chdir=infra/managed init -backend=false
terraform -chdir=infra/managed validate
python -m unittest discover -s .github/scripts -p 'test_*.py' -v
```

`infra/managed` é a definição usada pela Fase 3. O banco local para desenvolvimento sobe pelo Compose do [fiap-application](https://github.com/FIAP-GRUPO05/fiap-application).

A validação acima não provisiona recursos. Reconstrução, acesso ao RDS, isolamento dos ambientes e operação estão no [guia central](https://github.com/FIAP-GRUPO05/fiap-docs/blob/main/guides/database.md).
Consulte também o [estado da infraestrutura](https://github.com/FIAP-GRUPO05/fiap-docs/blob/main/operations/infrastructure-state.md).
