#!/bin/bash
# Vuelca el ESQUEMA REAL de prod (Kali Studio) a docs/db_schema.md.
#
# Por qué existe: las migraciones del repo divergieron del esquema vivo (p.ej.
# reservations NO tiene institution_id en prod, aunque varias migraciones lo
# asumen). Este dump es la FUENTE DE VERDAD del esquema: columnas, funciones,
# policies RLS, triggers y enums tal como están HOY en prod.
#
# Uso: scripts/dump_db_schema.sh   (lee el token del keychain de macOS)
# Requiere: token "Supabase CLI" en keychain + header User-Agent (ver
# memoria supabase-prod-sql-via-mgmt-api).

set -euo pipefail

PROJECT_REF="tmfcnvtjzmtpqhzvfxos"
OUT="$(cd "$(dirname "$0")/.." && pwd)/docs/db_schema.md"
mkdir -p "$(dirname "$OUT")"

TOKEN="$(security find-generic-password -s "Supabase CLI" -w 2>/dev/null || true)"
if [ -z "$TOKEN" ]; then
  echo "dump_db_schema: no encontré el token 'Supabase CLI' en el keychain; salto el dump." >&2
  exit 0
fi

# Corre una query y devuelve el JSON crudo de la Management API.
run() {
  curl -s --max-time 30 -X POST \
    "https://api.supabase.com/v1/projects/${PROJECT_REF}/database/query" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -H "User-Agent: supabase-cli/2.105.0" \
    -d "{\"query\": $(python3 -c 'import json,sys;print(json.dumps(sys.argv[1]))' "$1")}"
}

# --- Queries de introspección (todas devuelven una sola columna "md") -------

Q_TABLES=$(cat <<'SQL'
select string_agg(line, E'\n' order by tbl, ord) as md from (
  select c.relname as tbl, a.attnum as ord,
    '- `' || c.relname || '.' || a.attname || '` ' || format_type(a.atttypid, a.atttypmod)
      || case when a.attnotnull then ' NOT NULL' else '' end
      || coalesce(' default ' || pg_get_expr(ad.adbin, ad.adrelid), '') as line
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'public'
  join pg_attribute a on a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped
  left join pg_attrdef ad on ad.adrelid = c.oid and ad.adnum = a.attnum
  where c.relkind = 'r'
) x
SQL
)

Q_ENUMS=$(cat <<'SQL'
select coalesce(string_agg('- `' || t.typname || '` = ' || labels, E'\n' order by t.typname), '(sin enums)') as md
from pg_type t
join pg_namespace n on n.oid = t.typnamespace and n.nspname = 'public'
join (select enumtypid, string_agg(quote_literal(enumlabel), ', ' order by enumsortorder) labels
      from pg_enum group by enumtypid) e on e.enumtypid = t.oid
SQL
)

Q_FUNCS=$(cat <<'SQL'
select string_agg('### ' || p.proname || E'\n```sql\n' || pg_get_functiondef(p.oid) || E'\n```', E'\n\n' order by p.proname) as md
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace and n.nspname = 'public'
where p.prokind = 'f'
SQL
)

Q_POLICIES=$(cat <<'SQL'
select string_agg(line, E'\n' order by tbl, polname) as md from (
  select c.relname tbl, pol.polname,
    '- `' || c.relname || '` / **' || pol.polname || '** (' ||
      case pol.polcmd when 'r' then 'SELECT' when 'a' then 'INSERT' when 'w' then 'UPDATE'
                      when 'd' then 'DELETE' else 'ALL' end || ')'
      || coalesce(' USING ' || pg_get_expr(pol.polqual, pol.polrelid), '')
      || coalesce(' WITH CHECK ' || pg_get_expr(pol.polwithcheck, pol.polrelid), '') as line
  from pg_policy pol
  join pg_class c on c.oid = pol.polrelid
  join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'public'
) x
SQL
)

Q_TRIGGERS=$(cat <<'SQL'
select coalesce(string_agg('- `' || c.relname || '` → ' || t.tgname, E'\n' order by c.relname, t.tgname), '(sin triggers)') as md
from pg_trigger t
join pg_class c on c.oid = t.tgrelid
join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'public'
where not t.tgisinternal
SQL
)

# Extrae el campo "md" del JSON [{"md": "..."}]; vacío si error.
field() { python3 -c 'import json,sys
try:
    d=json.load(sys.stdin)
    print((d[0].get("md") or "") if isinstance(d,list) and d else "")
except Exception:
    print("")'; }

TABLES=$(run "$Q_TABLES" | field)
ENUMS=$(run "$Q_ENUMS" | field)
FUNCS=$(run "$Q_FUNCS" | field)
POLICIES=$(run "$Q_POLICIES" | field)
TRIGGERS=$(run "$Q_TRIGGERS" | field)

if [ -z "$TABLES" ]; then
  echo "dump_db_schema: la introspección volvió vacía (¿red/token?); no sobreescribo $OUT." >&2
  exit 0
fi

{
  echo "# Esquema real de prod — Kali Studio (\`$PROJECT_REF\`)"
  echo
  echo "> ⚠️ GENERADO AUTOMÁTICAMENTE por \`scripts/dump_db_schema.sh\`. No editar a mano."
  echo "> Snapshot del esquema **vivo** de prod. Es la FUENTE DE VERDAD por encima de"
  echo "> \`supabase/migrations/\` (el historial de migraciones está divergente)."
  echo ">"
  echo "> Generado: $(date '+%Y-%m-%d %H:%M %Z')"
  echo
  echo "## Tablas y columnas"
  echo; echo "$TABLES"
  echo
  echo "## Enums"
  echo; echo "$ENUMS"
  echo
  echo "## Políticas RLS"
  echo; echo "$POLICIES"
  echo
  echo "## Triggers"
  echo; echo "$TRIGGERS"
  echo
  echo "## Funciones / RPCs"
  echo; echo "$FUNCS"
} > "$OUT"

echo "dump_db_schema: esquema actualizado en $OUT"
