"""Create isolated application databases and credentials inside the private RDS."""

import json
import os
import uuid

import bcrypt
import boto3
import psycopg2
from botocore.exceptions import ClientError
from psycopg2 import sql


secrets = boto3.client("secretsmanager", region_name="sa-east-1")
master = json.loads(secrets.get_secret_value(SecretId=os.environ["MASTER_SECRET_ARN"])["SecretString"])


def application_secret(environment):
    name = f"fiap/{environment}/postgres"
    try:
        value = secrets.get_secret_value(SecretId=name)["SecretString"]
        credentials = json.loads(value)
        if credentials.get("host") != os.environ["DB_HOST"]:
            credentials["host"] = os.environ["DB_HOST"]
            secrets.put_secret_value(SecretId=name, SecretString=json.dumps(credentials))
        return credentials
    except ClientError as error:
        if error.response["Error"]["Code"] != "ResourceNotFoundException":
            raise

    username = f"oficina_{environment}"
    password = secrets.get_random_password(
        PasswordLength=40,
        ExcludePunctuation=True,
        RequireEachIncludedType=True,
    )["RandomPassword"]
    value = {"username": username, "password": password, "dbname": f"oficina_{environment}", "host": os.environ["DB_HOST"]}
    secrets.create_secret(
        Name=name,
        SecretString=json.dumps(value),
        Tags=[{"Key": "Project", "Value": "fiap-tech-challenge-fase-3"},
              {"Key": "Environment", "Value": environment}],
    )
    return value


def ensure_administrator(environment, credentials):
    with psycopg2.connect(host=credentials["host"], port=5432, dbname=credentials["dbname"],
            user=credentials["username"], password=credentials["password"], sslmode="require") as database:
        with database.cursor() as cursor:
            cursor.execute("SELECT to_regclass('public.users')")
            if cursor.fetchone()[0] is None:
                print(f"Administrator pending Flyway migrations: {environment}")
                return
            name = f"fiap/{environment}/admin"
            try:
                admin = json.loads(secrets.get_secret_value(SecretId=name)["SecretString"])
            except ClientError as error:
                if error.response["Error"]["Code"] != "ResourceNotFoundException":
                    raise
                admin = {"email": f"admin-{environment}@oficina.local", "password": secrets.get_random_password(
                    PasswordLength=40, ExcludePunctuation=True)["RandomPassword"]}
                secrets.create_secret(Name=name, SecretString=json.dumps(admin), Tags=[
                    {"Key": "Project", "Value": "fiap-tech-challenge-fase-3"}, {"Key": "Environment", "Value": environment}])
            cursor.execute("SELECT role FROM users WHERE email = %s", (admin["email"],))
            existing = cursor.fetchone()
            if existing:
                if existing[0] != "ROLE_ADMIN":
                    raise RuntimeError(f"Administrator email already belongs to another role: {environment}")
            else:
                hashed = bcrypt.hashpw(admin["password"].encode(), bcrypt.gensalt()).decode()
                cursor.execute("INSERT INTO users (id, email, password, role) VALUES (%s, %s, %s, 'ROLE_ADMIN')",
                    (str(uuid.uuid4()), admin["email"], hashed))
            # Synthetic CPF fixtures are confined to nonproduction databases.
            if environment in {"develop", "homol"}:
                for document, status in (("52998224725", "ACTIVE"), ("11144477735", "INACTIVE")):
                    cursor.execute("""INSERT INTO customers (id, name, email, phone, cnpj_cpf, status)
                        VALUES (%s, %s, %s, '11999998888', %s, %s) ON CONFLICT (cnpj_cpf) DO NOTHING""",
                        (str(uuid.uuid5(uuid.NAMESPACE_URL, f"fiap/{environment}/{document}")),
                         "CI CPF fixture", f"fixture-{status.lower()}@example.test", document, status))
    print(f"Administrator ready; credentials remain in Secrets Manager: {environment}")


def application_runtime_secret(environment):
    name = f"fiap/{environment}/application"
    try:
        return secrets.get_secret_value(SecretId=name)["SecretString"]
    except ClientError as error:
        if error.response["Error"]["Code"] != "ResourceNotFoundException":
            raise
    value = {"jwt_secret": secrets.get_random_password(PasswordLength=64, ExcludePunctuation=True)["RandomPassword"]}
    secrets.create_secret(
        Name=name,
        SecretString=json.dumps(value),
        Tags=[{"Key": "Project", "Value": "fiap-tech-challenge-fase-3"},
              {"Key": "Environment", "Value": environment}],
    )
    return json.dumps(value)


connection = psycopg2.connect(
    host=os.environ["DB_HOST"],
    port=5432,
    dbname="postgres",
    user=master["username"],
    password=master["password"],
    sslmode="require",
)
connection.autocommit = True
try:
    with connection.cursor() as cursor:
        for environment in ("develop", "homol", "prod"):
            credentials = application_secret(environment)
            application_runtime_secret(environment)
            username = credentials["username"]
            database = credentials["dbname"]

            cursor.execute("SELECT 1 FROM pg_roles WHERE rolname = %s", (username,))
            if cursor.fetchone():
                cursor.execute(
                    sql.SQL("ALTER ROLE {} WITH LOGIN PASSWORD %s").format(sql.Identifier(username)),
                    (credentials["password"],),
                )
            else:
                cursor.execute(
                    sql.SQL("CREATE ROLE {} WITH LOGIN PASSWORD %s").format(sql.Identifier(username)),
                    (credentials["password"],),
                )

            cursor.execute("SELECT 1 FROM pg_database WHERE datname = %s", (database,))
            if not cursor.fetchone():
                cursor.execute(
                    sql.SQL("CREATE DATABASE {}").format(sql.Identifier(database))
                )

            cursor.execute(
                sql.SQL("REVOKE CONNECT ON DATABASE {} FROM PUBLIC").format(sql.Identifier(database))
            )
            cursor.execute(
                sql.SQL("GRANT CONNECT, CREATE, TEMPORARY ON DATABASE {} TO {}").format(
                    sql.Identifier(database), sql.Identifier(username)
                )
            )

            app_connection = psycopg2.connect(
                host=os.environ["DB_HOST"],
                port=5432,
                dbname=database,
                user=master["username"],
                password=master["password"],
                sslmode="require",
            )
            app_connection.autocommit = True
            try:
                with app_connection.cursor() as app_cursor:
                    app_cursor.execute(
                        sql.SQL("GRANT ALL ON SCHEMA public TO {}").format(sql.Identifier(username))
                    )
            finally:
                app_connection.close()
            ensure_administrator(environment, credentials)
            print(f"Database and application user ready: {environment}")
finally:
    connection.close()
