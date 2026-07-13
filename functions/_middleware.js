// Cloudflare Pages Functions — middleware global.
//
// Reset ÚNICO por navegador para sacar a los usuarios de una versión vieja
// cacheada (la que tenía el login roto). En la respuesta del documento HTML,
// y solo si el navegador todavía no fue reseteado, manda:
//
//   Clear-Site-Data: "storage"
//
// que borra: CacheStorage (donde el SW guardaba la app vieja), IndexedDB/
// localStorage (la sesión) y los service workers registrados. Acto seguido
// setea una cookie para NO repetirlo (así no quedan en un loop de deslogueo).
// Los usuarios se deslogean una sola vez y vuelven a entrar contra el build
// nuevo, que ya loguea bien.
//
// OJO: NO se incluye "cache". Ese directivo limpia el HTTP cache del que
// depende la navegación en curso y puede dejar la primera carga EN BLANCO
// (bug conocido de Chrome). Además es redundante: los archivos de entrada ya
// salen con no-cache (web/_headers), así que el HTTP cache ya se revalida solo.
//
// Nota: a los usuarios que todavía tienen el SW viejo de Flutter este header no
// los alcanza (el SW sirve la navegación desde su propia caché, sin pegarle a
// la red); a esos los cura el flutter_service_worker.js autodestructivo. Entre
// los dos mecanismos se cubren todos los casos.
//
// Para volver a forzar un reset en el futuro, cambiá el valor de RESET_ID.

const RESET_ID = '20260712';
const COOKIE = 'kali_reset';

export async function onRequest(context) {
  const { request, next } = context;
  const response = await next();

  try {
    // Rescate de builds rotos: la app vieja (compilada con SUPABASE_URL vacía)
    // POSTea el login a ESTE origen (/auth/v1/token) y recibe un 405 inútil.
    // Esas rutas solo las pide un build roto (el build sano le pega a
    // *.supabase.co), así que la respuesta lleva Clear-Site-Data para que el
    // propio intento de login le borre el SW y la caché; al reintentar carga
    // fresco. Sin cookie: si el navegador ignora el header (Safari < 17), no
    // quemamos el reset del HTML.
    //
    // Acá SÍ va "cache": el HTTP cache guarda los /assets/* de la época
    // "immutable" (hasta 1 año, sin revalidar) y es donde vive el assets/.env
    // roto que deja al usuario en el loop del 405. El bug de la carga en
    // blanco de Chrome aplica a limpiar el cache en la respuesta de una
    // NAVEGACIÓN; esto es la respuesta de un fetch (el POST del login), no hay
    // navegación en vuelo, así que es seguro.
    const url = new URL(request.url);
    if (url.pathname.startsWith('/auth/v1/') || url.pathname.startsWith('/rest/v1/')) {
      const rescue = new Response(response.body, response);
      rescue.headers.set('Clear-Site-Data', '"cache", "storage"');
      return rescue;
    }

    // ¿Ya fue reseteado este navegador?
    const cookies = request.headers.get('Cookie') || '';
    if (cookies.includes(COOKIE + '=' + RESET_ID)) return response;

    // Actuar solo sobre el documento HTML (la navegación), no sobre cada asset.
    const ct = response.headers.get('Content-Type') || '';
    if (!ct.includes('text/html')) return response;

    const out = new Response(response.body, response);
    out.headers.set('Clear-Site-Data', '"storage"');
    out.headers.append(
      'Set-Cookie',
      COOKIE + '=' + RESET_ID + '; Path=/; Max-Age=31536000; Secure; SameSite=Lax; HttpOnly',
    );
    return out;
  } catch (e) {
    // Ante cualquier error, no romper el sitio: devolver la respuesta original.
    return response;
  }
}
