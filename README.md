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

## Membros da equipe

<table>
  <tr>
    <td align="center" width="160">
      <a href="https://www.linkedin.com/in/wesslima/" title="Wesley Lima">
        <img src="https://raw.githubusercontent.com/FIAP-GRUPO05/fiap-docs/main/assets/team/wesley-lima.jpg" width="100" height="100" alt="Foto de Wesley Lima"><br>
        <sub><b>Wesley Lima</b></sub>
      </a><br><sub>Backend Engineer</sub>
    </td>
    <td align="center" width="160">
      <a href="https://www.linkedin.com/in/tim-morgenstern-4581911b1/" title="Tim Morgenstern">
        <img src="https://raw.githubusercontent.com/FIAP-GRUPO05/fiap-docs/main/assets/team/tim-morgenstern.jpg" width="100" height="100" alt="Foto de Tim Morgenstern"><br>
        <sub><b>Tim Morgenstern</b></sub>
      </a><br><sub>Backend Engineer</sub>
    </td>
    <td align="center" width="160">
      <a href="https://www.linkedin.com/in/matheus-pitas-baptista/" title="Matheus Pitas Baptista">
        <img src="https://raw.githubusercontent.com/FIAP-GRUPO05/fiap-docs/main/assets/team/matheus-pitas.jpg" width="100" height="100" alt="Foto de Matheus Pitas Baptista"><br>
        <sub><b>Matheus Pitas Baptista</b></sub>
      </a><br><sub>Backend Engineer</sub>
    </td>
  </tr>
</table>
