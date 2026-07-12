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
# --pwa-strategy=none: NO generar el service worker de Flutter. Evita que los
# usuarios queden con una versión vieja cacheada; la caché la controlan los
# headers HTTP de web/_headers (no-cache en los archivos de entrada).
flutter build web --release --pwa-strategy=none
