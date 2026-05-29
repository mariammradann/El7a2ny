import pytest
from django.db.backends.signals import connection_created
from django.dispatch import receiver

@receiver(connection_created)
def create_ems_schema(sender, connection, **kwargs):
    """
    Ensure the custom ems_schema exists in the PostgreSQL database (especially the test database)
    before Django attempts to run migrations and create tables.
    """
    with connection.cursor() as cursor:
        cursor.execute("CREATE SCHEMA IF NOT EXISTS ems_schema;")
