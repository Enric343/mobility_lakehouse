"""Run SQL quality checks and stop before committing a failed batch."""

from .catalog import read_sql


class QualityError(ValueError):
    """Source data or a transformation fails a lakehouse quality check."""


def require_checks(connection, path):
    results = connection.execute(read_sql(f"validation/{path}")).fetchall()
    for name, issues in results:
        print(f"{'FAIL' if issues else 'PASS'} {name} ({issues} issues)", flush=True)
    if any(issues for _, issues in results):
        raise QualityError(f"Checks failed in sql/validation/{path}")
