#!/bin/bash
# Script para compilar Flutter en Cloudflare Pages

# 1. Clonar el repositorio de Flutter (versión estable)
git clone https://github.com/flutter/flutter.git -b stable

# 2. Agregar Flutter al PATH temporalmente para la compilación
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Habilitar soporte web
flutter config --enable-web

# 4. Crear archivo .env temporal para que la compilación de assets no falle
# Se tomarán las variables de entorno configuradas en Cloudflare Pages
# Las claves DEBEN llamarse igual que las que lee la app (lib/main.dart):
# SUPABASE_URL / SUPABASE_ANON. Los valores vienen de las env vars URL/ANON
# configuradas en Cloudflare Pages.
cat <<EOF > .env
SUPABASE_URL='${URL}'
SUPABASE_ANON='${ANON}'
EOF

# 5. Compilar la aplicación para producción
flutter build web --release
