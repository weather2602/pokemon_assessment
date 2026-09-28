import subprocess
import sys


def run_command(cmd):
    print(f"Executing: {' '.join(cmd)}")
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print("Error executing command!")
            print("STDOUT:")
            print(result.stdout)
            print("STDERR:")
            print(result.stderr)
            sys.exit(1)
        else:
            print(result.stdout)
    except FileNotFoundError:
        print("\n[!] Error: 'dbt' executable not found in your current path.")
        print(
            "Please ensure your Python environment is activated and dbt-duckdb is installed:"
        )
        print("  pip install dbt-duckdb")
        print("\nOnce installed and activated, run this script again.")
        sys.exit(1)


def main():
    # 1. Run dbt models
    print("=== Step 1: Running dbt Models ===")
    run_command(["dbt", "run", "--profiles-dir", "."])

    # 2. Run dbt tests
    print("=== Step 2: Running dbt Quality Tests ===")
    run_command(["dbt", "test", "--profiles-dir", "."])

    # 3. Export to CSV
    print("=== Step 3: Exporting Unified Staging Table to CSV ===")
    try:
        import duckdb

        con = duckdb.connect("dev.duckdb")
        con.execute(
            "COPY stg_pokemon_unified TO 'staged_pokemon_unified.csv' (HEADER, DELIMITER ',')"
        )
        print("Successfully exported 'staged_pokemon_unified.csv'!")

        # Count rows exported
        count = con.execute("SELECT COUNT(*) FROM stg_pokemon_unified").fetchone()[0]
        print(f"Exported {count} rows.")

        # Preview of the exported data
        print("\nPreview of stg_pokemon_unified table:")
        df = con.execute(
            "SELECT pokemon_id, pokemon_name, primary_type, secondary_type, is_legendary, source_file FROM stg_pokemon_unified LIMIT 5"
        ).fetchdf()
        print(df.to_string(index=False))
        con.close()
    except Exception as e:
        print(f"Error exporting database: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
