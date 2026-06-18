import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const allowedOrigins = [
  'https://turnos.argity.com',
  'https://tmfcnvtjzmtpqhzvfxos.supabase.co',
];

function corsHeaders(req: Request) {
  const origin = req.headers.get('Origin') ?? '';
  const allowed = allowedOrigins.includes(origin) ? origin : allowedOrigins[0];
  return {
    'Access-Control-Allow-Origin': allowed,
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };
}

serve(async (req) => {
  console.log('delete-account request:', req.method, 'origin:', req.headers.get('Origin'));

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders(req) });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Tu sesión expiró. Volvé a iniciar sesión.' }), {
        status: 401, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
      });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // Identificar al usuario a partir de SU PROPIO token: nadie puede borrar
    // la cuenta de otra persona, solo la suya.
    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Tu sesión expiró. Volvé a iniciar sesión.' }), {
        status: 401, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
      });
    }

    // Anonimizar las referencias de "actor" antes de borrar el profile.
    // Estas 3 FK son ON DELETE NO ACTION (no cascade): si este usuario es
    // instructor/admin y canceló/procesó/creó registros de OTRAS personas,
    // esas filas apuntan a su id y bloquearían el DELETE del profile.
    // Las ponemos en null (la columna es nullable): el registro ajeno se
    // conserva, pero deja de identificar al usuario que se va.
    await Promise.all([
      supabase.from('reservations').update({ cancelled_by: null }).eq('cancelled_by', user.id),
      supabase.from('payments').update({ processed_by: null }).eq('processed_by', user.id),
      supabase.from('subscriptions').update({ created_by: null }).eq('created_by', user.id),
    ]);

    // Borrar la fila de profiles: las tablas dependientes con FK ON DELETE
    // CASCADE hacia profiles (reservations.user_id, payments.user_id,
    // subscriptions.user_id, notifications.user_id) se limpian solas.
    // waitlist y push_subscriptions cuelgan de auth.users → se limpian en
    // el deleteUser de abajo.
    const { error: profileError } = await supabase
      .from('profiles')
      .delete()
      .eq('id', user.id);

    if (profileError) {
      console.error('profiles delete error:', profileError.message);
      return new Response(JSON.stringify({ error: 'No pudimos borrar tus datos. Intentá de nuevo en unos minutos.' }), {
        status: 500, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
      });
    }

    // Borrar la cuenta de auth: a partir de acá el usuario no puede volver a loguear.
    const { error: deleteError } = await supabase.auth.admin.deleteUser(user.id);
    if (deleteError) {
      console.error('auth deleteUser error:', deleteError.message);
      return new Response(JSON.stringify({ error: 'Borramos tus datos pero no pudimos cerrar la cuenta. Escribinos a soporte.' }), {
        status: 500, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
      });
    }

    console.log('account deleted:', user.id);

    return new Response(JSON.stringify({ ok: true }), {
      status: 200, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
    });

  } catch (e) {
    console.error(e);
    return new Response(JSON.stringify({ error: 'Algo salió mal de nuestro lado. Intentá de nuevo en unos segundos.' }), {
      status: 500, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
    });
  }
});
