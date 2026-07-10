#!/usr/bin/env python3
"""Valida que el SQL no referencie columnas que NO existen en el esquema real de prod.

Atrapa exactamente el bug del 2026-07-01: `insert into reservations (..., institution_id)`
cuando reservations no tiene esa columna. Postgres NO rechaza eso al crear una función
(solo falla en runtime), asi que este chequeo estatico es la unica red que lo agarra
antes de aplicar.

Fuente de verdad del esquema: docs/db_schema.md (lo regenera scripts/dump_db_schema.sh
en cada SessionStart). Lineas tipo `- \`tabla.columna\` tipo ...`.

Uso:
  - CLI:   scripts/lint_sql_schema.py archivo.sql
  - Hook:  scripts/lint_sql_schema.py --hook   (lee JSON de PreToolUse por stdin)

Exit codes: 0 = OK / no aplica; 2 = encontro columnas inexistentes (bloquea el hook).
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SCHEMA_DOC = os.path.join(ROOT, "docs", "db_schema.md")


def load_schema_columns():
    """Devuelve {tabla: set(columnas)} leido de docs/db_schema.md, o None si falta."""
    if not os.path.exists(SCHEMA_DOC):
        return None
    cols = {}
    rx = re.compile(r"^- `([a-z_][a-z0-9_]*)\.([a-z_][a-z0-9_]*)`", re.IGNORECASE)
    with open(SCHEMA_DOC, encoding="utf-8") as fh:
        for line in fh:
            m = rx.match(line.strip())
            if m:
                cols.setdefault(m.group(1).lower(), set()).add(m.group(2).lower())
    return cols or None


def strip_comments(sql):
    """Saca comentarios SQL para no matchear referencias mencionadas en texto explicativo
    (ej. un comentario que documenta el bug: `insert into reservations (..., institution_id)`)."""
    sql = re.sub(r"/\*.*?\*/", " ", sql, flags=re.DOTALL)   # bloque /* */
    sql = re.sub(r"--[^\n]*", " ", sql)                      # linea --
    return sql


def _clean(col):
    return col.strip().strip('"').strip("`").lower()


def columns_defined_in_sql(sql):
    """Tablas creadas y columnas agregadas DENTRO del mismo SQL (para no falsos positivos
    cuando la migracion crea la tabla o agrega la columna antes de usarla)."""
    created_tables = set(
        _clean(t) for t in re.findall(
            r"create\s+table\s+(?:if\s+not\s+exists\s+)?(?:public\.)?(\"?[a-z_][a-z0-9_]*\"?)",
            sql, re.IGNORECASE)
    )
    added = {}
    for m in re.finditer(
        r"alter\s+table\s+(?:if\s+exists\s+)?(?:only\s+)?(?:public\.)?(\"?[a-z_][a-z0-9_]*\"?)"
        r"[\s\S]*?add\s+column\s+(?:if\s+not\s+exists\s+)?(\"?[a-z_][a-z0-9_]*\"?)",
        sql, re.IGNORECASE,
    ):
        added.setdefault(_clean(m.group(1)), set()).add(_clean(m.group(2)))
    return created_tables, added


def find_insert_issues(sql, schema):
    """Devuelve lista de (tabla, columna) referenciadas en INSERT que no existen."""
    created, added = columns_defined_in_sql(sql)
    issues = []
    # insert into [public.]tabla ( col, col, ... )
    for m in re.finditer(
        r"insert\s+into\s+(?:public\.)?(\"?[a-z_][a-z0-9_]*\"?)\s*\(([^)]*)\)",
        sql, re.IGNORECASE,
    ):
        table = _clean(m.group(1))
        if table in created:            # la tabla se crea en este mismo SQL
            continue
        if table not in schema:         # tabla desconocida (otra schema, vista, etc.): no opinamos
            continue
        known = schema[table] | added.get(table, set())
        for raw in m.group(2).split(","):
            col = _clean(raw)
            if not col or not re.match(r"^[a-z_][a-z0-9_]*$", col):
                continue                # expresiones raras: no opinamos
            if col not in known:
                issues.append((table, col))
    # dedup preservando orden
    seen, out = set(), []
    for it in issues:
        if it not in seen:
            seen.add(it); out.append(it)
    return out


def sql_from_hook_stdin():
    """Extrae el SQL a validar del JSON de PreToolUse. Devuelve (sql, path) o (None, None)."""
    try:
        data = json.load(sys.stdin)
    except Exception:
        return None, None
    ti = data.get("tool_input", {}) or {}
    path = ti.get("file_path", "") or ""
    if not path.endswith(".sql"):
        return None, None
    tool = data.get("tool_name", "")
    if tool == "Write":
        return ti.get("content", "") or "", path
    if tool == "Edit":
        return ti.get("new_string", "") or "", path
    if tool == "MultiEdit":
        return "\n".join(e.get("new_string", "") for e in ti.get("edits", [])), path
    return None, None


def report(issues, path, schema_missing):
    if schema_missing:
        # No podemos validar; no bloqueamos, solo avisamos por stderr.
        sys.stderr.write(
            "lint_sql_schema: falta docs/db_schema.md; no pude validar columnas. "
            "Corré scripts/dump_db_schema.sh.\n")
        return 0
    if not issues:
        return 0
    lines = [f"❌ SQL rechazado: columnas que NO existen en el esquema real de prod ({path}):"]
    for table, col in issues:
        lines.append(f"   - `{table}.{col}` no existe. Revisá docs/db_schema.md.")
    lines.append(
        "Esto es justo el error del 2026-07-01. Corregí la referencia o, si de verdad "
        "hace falta la columna, agregala con un ALTER TABLE en el mismo archivo antes de usarla.")
    sys.stderr.write("\n".join(lines) + "\n")
    return 2


def main():
    schema = load_schema_columns()
    schema_missing = schema is None
    # (sql se limpia de comentarios mas abajo, una vez obtenido)

    if len(sys.argv) > 1 and sys.argv[1] == "--hook":
        sql, path = sql_from_hook_stdin()
        if sql is None:
            return 0  # no es un .sql / tool no relevante
    elif len(sys.argv) > 1:
        path = sys.argv[1]
        try:
            with open(path, encoding="utf-8") as fh:
                sql = fh.read()
        except OSError as e:
            sys.stderr.write(f"lint_sql_schema: no pude leer {path}: {e}\n")
            return 0
    else:
        sql, path = sys.stdin.read(), "(stdin)"

    if schema_missing:
        return report([], path, True)
    issues = find_insert_issues(strip_comments(sql), schema)
    return report(issues, path, False)


if __name__ == "__main__":
    sys.exit(main())
