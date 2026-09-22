import sys
import time
from pathlib import Path


S3_BUCKET = "s3://vhm-data-platform-sharing-stag"


def gen_with_s3(paths: list[str]) -> str:
    queries = []

    for idx, s3_path in enumerate(paths):
        s3_path = s3_path.strip().strip("/")

        if not s3_path:
            continue

        queries.append(
            f"SELECT {idx} AS ord, "
            f"'{s3_path}' AS s3_path, "
            f"count(1) AS cnt "
            f"FROM delta.`{S3_BUCKET}/{s3_path}`"
        )

    return "\nUNION ALL\n".join(queries)


def gen_with_clickhouse(tables: list[str]) -> str:
    queries = []

    for idx, table_name in enumerate(tables):
        table_name = table_name.strip()

        if not table_name:
            continue

        queries.append(
            f"SELECT {idx} AS ord, "
            f"'{table_name}' AS table_name, "
            f"count(1) AS cnt "
            f"FROM {table_name}"
        )

    return "\nUNION ALL\n".join(queries)


def generate_sql(inputs: list[str]) -> str:
    """
    Detect input type:
      - contains "/" -> S3 path
      - no "/"       -> table name
    """

    s3_paths = []
    tables = []

    for value in inputs:
        value = value.strip()

        if not value:
            continue

        if "/" in value:
            s3_paths.append(value)
        else:
            tables.append(value)

    results = []

    if tables:
        results.append(gen_with_clickhouse(tables))

    if s3_paths:
        results.append(gen_with_s3(s3_paths))

    return "\nUNION ALL\n".join(results)


def main():
    if len(sys.argv) < 2:
        print(f"Usage: python {sys.argv[0]} <input1> [input2] ...")
        print()
        print("Examples:")
        print(f"  python {sys.argv[0]} database.table1 database.table2")
        print(f"  python {sys.argv[0]} path/to/table1 path/to/table2")
        sys.exit(1)

    inputs = sys.argv[1:]

    result = generate_sql(inputs)

    timestamp = int(time.time() * 1000)
    target_file = Path(f"/tmp/generate_sql_{timestamp}.sql")

    target_file.write_text(result + "\n", encoding="utf-8")

    print(result)
    print()
    print("=" * 80)
    print(f"Output: {target_file}")


if __name__ == "__main__":
    main()
