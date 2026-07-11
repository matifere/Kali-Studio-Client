import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Login con código de acceso generado por el admin (tabla access_codes).
// El cliente manda { code } SIN sesión; acá se valida con service role y se
// emite un token de magiclink. La app termina el login con verifyOtp
// (tokenHash), y la institución sale sola del perfil del alumno.
//
// Se refleja el Origin del request porque este endpoint se usa antes de tener
// sesión (web local, turnos.argity.com y apps móviles sin Origin); la
// autorización real es el código en sí, no el origen.
function corsHeaders(req: Request) {
  return {
    'Access-Control-Allow-Origin': req.headers.get('Origin') ?? '*',
    'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type',
  };
}

function jsonResponse(req: Request, status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
  });
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders(req) });
  }

  try {
    const { code } = await req.json().catch(() => ({}));

    // Normalizar: mayúsculas y solo el alfabeto del código (el usuario puede
    // tipear con guiones, espacios o minúsculas).
    const normalized = (typeof code === 'string' ? code : '')
      .toUpperCase()
      .replace(/[^A-Z2-9]/g, '');

    if (normalized.length < 6) {
      return jsonResponse(req, 400, { error: 'Ingresá un código válido.' });
    }

    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data: ac, error: acError } = await admin
      .from('access_codes')
      .select('id, user_id, use_count, profiles!access_codes_user_id_fkey(is_active, email)')
      .eq('code', normalized)
      .is('revoked_at', null)
      .maybeSingle();

    if (acError) {
      console.error('access_codes lookup error:', acError.message);
      return jsonResponse(req, 500, {
        error: 'No pudimos validar el código. Intentá de nuevo.',
      });
    }

    if (!ac) {
      return jsonResponse(req, 404, {
        error: 'Código inválido o vencido. Pedile uno nuevo a tu gimnasio.',
      });
    }

    const profile = ac.profiles as unknown as
      | { is_active: boolean; email: string | null }
      | null;

    if (!profile?.is_active) {
      return jsonResponse(req, 403, {
        error: 'Tu cuenta está inactiva. Consultá en tu gimnasio.',
      });
    }

    // Email desde auth.users (fuente de verdad); el del perfil es fallback.
    const { data: userData } = await admin.auth.admin.getUserById(ac.user_id);
    const email = userData?.user?.email ?? profile.email;

    if (!email) {
      console.error('access code without email, user:', ac.user_id);
      return jsonResponse(req, 500, {
        error: 'No pudimos validar el código. Intentá de nuevo.',
      });
    }

    const { data: linkData, error: linkError } =
      await admin.auth.admin.generateLink({ type: 'magiclink', email });

    if (linkError || !linkData?.properties?.hashed_token) {
      console.error('generateLink error:', linkError?.message);
      return jsonResponse(req, 500, {
        error: 'No pudimos iniciar sesión con el código. Intentá de nuevo.',
      });
    }

    await admin
      .from('access_codes')
      .update({ last_used_at: new Date().toISOString(), use_count: ac.use_count + 1 })
      .eq('id', ac.id);

    return jsonResponse(req, 200, {
      token_hash: linkData.properties.hashed_token,
    });
  } catch (e) {
    console.error('login-with-code error:', e);
    return jsonResponse(req, 500, {
      error: 'No pudimos validar el código. Intentá de nuevo.',
    });
  }
});
