"""Regression for restored Secrets Manager credentials pointing to a deleted RDS."""
import ast
import json
import os
from pathlib import Path
import unittest
from unittest.mock import MagicMock, patch

source = Path(__file__).resolve().parents[2] / "infra/managed/bootstrap_databases.py"
tree = ast.parse(source.read_text(encoding="utf-8"))
function = next(node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name == "application_secret")


class RestoredDatabaseSecretTests(unittest.TestCase):
    def run_case(self, old_host):
        client = MagicMock()
        credentials = {"username": "oficina_prod", "password": "synthetic-test-password", "dbname": "oficina_prod"}
        if old_host is not None: credentials["host"] = old_host
        client.get_secret_value.return_value = {"SecretString": json.dumps(credentials)}
        scope = {"secrets": client, "json": json, "os": os, "ClientError": RuntimeError}
        exec(compile(ast.Module(body=[function], type_ignores=[]), str(source), "exec"), scope)
        with patch.dict(os.environ, {"DB_HOST": "new-private-rds.example.test"}):
            result = scope["application_secret"]("prod")
        self.assertEqual(result["host"], "new-private-rds.example.test")
        self.assertEqual(result["username"], credentials["username"])
        self.assertEqual(result["password"], credentials["password"])
        client.get_random_password.assert_not_called()
        client.create_secret.assert_not_called()
        return client

    def test_old_endpoint_is_replaced_without_rotating_credentials(self):
        client = self.run_case("deleted-rds.example.test")
        saved = json.loads(client.put_secret_value.call_args.kwargs["SecretString"])
        self.assertEqual(saved["host"], "new-private-rds.example.test")

    def test_missing_endpoint_is_initialized(self):
        self.run_case(None).put_secret_value.assert_called_once()

    def test_current_endpoint_does_not_create_redundant_secret_versions(self):
        self.run_case("new-private-rds.example.test").put_secret_value.assert_not_called()
