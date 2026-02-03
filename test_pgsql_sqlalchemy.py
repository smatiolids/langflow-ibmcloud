#!/usr/bin/env python3
"""
Simple PostgreSQL connection test using SQLAlchemy.

Usage:
  python test_pgsql_sqlalchemy.py
  python test_pgsql_sqlalchemy.py --url "postgresql+psycopg://user:pass@host:5432/dbname?sslmode=require"

By default, the script reads the URL from LANGFLOW_DATABASE_URL or DATABASE_URL.
"""

import argparse
import os
import sys

from sqlalchemy import create_engine, text


def normalize_url(url: str) -> str:
    # SQLAlchemy expects the PostgreSQL scheme to be postgresql://
    if url.startswith("postgres://"):
        return "postgresql://" + url[len("postgres://") :]
    return url


def main() -> int:
    parser = argparse.ArgumentParser(description="Test PostgreSQL connection with SQLAlchemy.")
    parser.add_argument(
        "--url",
        default=os.getenv("LANGFLOW_DATABASE_URL") or os.getenv("DATABASE_URL"),
        help="PostgreSQL connection URL. Defaults to LANGFLOW_DATABASE_URL or DATABASE_URL.",
    )
    args = parser.parse_args()

    if not args.url:
        print("Missing database URL.")
        print("Set LANGFLOW_DATABASE_URL (or DATABASE_URL), or pass --url.")
        return 1

    db_url = normalize_url(args.url)

    try:
        engine = create_engine(db_url, pool_pre_ping=True)
        with engine.connect() as connection:
            result = connection.execute(
                text(
                    "SELECT current_database() AS db, current_user AS username, version() AS version, now() AS server_time"
                )
            ).mappings().first()

        print("Connection successful.")
        print(f"Database   : {result['db']}")
        print(f"User       : {result['username']}")
        print(f"Server time: {result['server_time']}")
        print(f"Version    : {result['version']}")
        return 0
    except Exception as exc:
        print(f"Connection failed: {exc}")
        return 2


if __name__ == "__main__":
    sys.exit(main())
