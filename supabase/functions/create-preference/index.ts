import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const allowedOrigins = [
  'http://localhost:56078',
  'https://tmfcnvtjzmtpqhzvfxos.supabase.co',
  'https://chimpace-turnos.web.app',
  'https://chimpace-turnos.firebaseapp.com',
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
  console.log('request:', req.method, req.url, 'origin:', req.headers.get('Origin'));

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders(req) });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'No autenticado' }), {
        status: 401, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
      });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'No autenticado' }), {
        status: 401, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
      });
    }

    const { plan_id } = await req.json();
    if (!plan_id) {
      return new Response(JSON.stringify({ error: 'plan_id requerido' }), {
        status: 400, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
      });
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('institution_id')
      .eq('id', user.id)
      .single();

    const { data: plan, error: planError } = await supabase
      .from('plans')
      .select('id, name, price, currency, institution_id')
      .eq('id', plan_id)
      .eq('is_active', true)
      .single();

    if (planError || !plan) {
      return new Response(JSON.stringify({ error: 'Plan no encontrado' }), {
        status: 404, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
      });
    }

    if (profile?.institution_id && plan.institution_id !== profile.institution_id) {
      return new Response(JSON.stringify({ error: 'Plan no disponible' }), {
        status: 403, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
      });
    }

    const institutionId = plan.institution_id ?? profile?.institution_id;
    console.log('institutionId:', institutionId);

    // ── Determine payment method ──────────────────────────────────────────────
    let mpAccessToken: string | null = null;
    let transferAlias: string | null = null;

    if (institutionId) {
      // 1. Try institution MP token from vault
      const { data: vaultToken, error: vaultError } = await supabase.rpc('get_institution_mp_token', {
        p_institution_id: institutionId,
      });
      console.log('vaultToken present:', !!vaultToken, 'vaultError:', vaultError?.message);
      mpAccessToken = vaultToken as string | null;

      // 2. If no MP token, check institution alias
      if (!mpAccessToken) {
        const { data: inst } = await supabase
          .from('institutions')
          .select('payment_alias')
          .eq('id', institutionId)
          .maybeSingle();
        transferAlias = inst?.payment_alias ?? null;
        console.log('payment_alias present:', !!transferAlias);
      }
    }

    // 3. Fall back to global env MP token only if no alias configured
    if (!mpAccessToken && !transferAlias) {
      mpAccessToken = Deno.env.get('MP_ACCESS_TOKEN') ?? null;
      console.log('fallback env token present:', !!mpAccessToken);
    }

    if (!mpAccessToken && !transferAlias) {
      console.error('No payment method found for institutionId:', institutionId);
      return new Response(JSON.stringify({ error: 'Institución sin configuración de pago' }), {
        status: 503, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
      });
    }

    // ── Create pending subscription + payment (both paths) ───────────────────
    const toDate = (d: Date) => d.toISOString().substring(0, 10);
    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + 30);

    const { data: subscription, error: subError } = await supabase
      .from('subscriptions')
      .insert({
        user_id: user.id,
        plan_id: plan.id,
        status: 'pending',
        start_date: toDate(startDate),
        end_date: toDate(endDate),
      })
      .select('id')
      .single();

    if (subError || !subscription) {
      console.error('Subscription insert error:', subError?.message);
      return new Response(JSON.stringify({ error: 'Error al registrar la suscripción' }), {
        status: 500, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
      });
    }

    const { data: paymentRecord, error: paymentInsertError } = await supabase
      .from('payments')
      .insert({
        user_id: user.id,
        subscription_id: subscription.id,
        amount: Number(plan.price),
        currency: plan.currency ?? 'ARS',
        status: 'pending',
        institution_id: institutionId ?? null,
      })
      .select('id')
      .single();

    if (paymentInsertError || !paymentRecord) {
      console.error('Payment insert error:', paymentInsertError?.message);
      await supabase.from('subscriptions').delete().eq('id', subscription.id);
      return new Response(JSON.stringify({ error: 'Error al registrar el pago' }), {
        status: 500, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
      });
    }

    console.log('subscription:', subscription.id, 'payment:', paymentRecord.id);

    // ── Alias / transfer path ─────────────────────────────────────────────────
    if (transferAlias) {
      return new Response(JSON.stringify({ alias: transferAlias }), {
        status: 200, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
      });
    }

    // ── MercadoPago path ──────────────────────────────────────────────────────
    const mpResponse = await fetch('https://api.mercadopago.com/checkout/preferences', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${mpAccessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        items: [{
          id: plan.id,
          title: plan.name,
          quantity: 1,
          unit_price: Number(plan.price),
          currency_id: plan.currency ?? 'ARS',
        }],
        external_reference: paymentRecord.id,
        back_urls: {
          success: 'https://chimpace-turnos.web.app',
          failure: 'https://chimpace-turnos.web.app',
          pending: 'https://chimpace-turnos.web.app',
        },
        auto_return: 'approved',
        notification_url: `${Deno.env.get('SUPABASE_URL')}/functions/v1/mp-webhook`,
      }),
    });

    if (!mpResponse.ok) {
      const mpErr = await mpResponse.text();
      console.error('MP error:', mpErr);
      await supabase.from('payments').delete().eq('id', paymentRecord.id);
      await supabase.from('subscriptions').delete().eq('id', subscription.id);
      return new Response(JSON.stringify({ error: 'Error al crear el pago' }), {
        status: 500, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
      });
    }

    const preference = await mpResponse.json();

    await supabase.from('payments')
      .update({ preference_id: preference.id })
      .eq('id', paymentRecord.id);

    return new Response(JSON.stringify({ url: preference.init_point }), {
      status: 200, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
    });

  } catch (e) {
    console.error(e);
    return new Response(JSON.stringify({ error: 'Error interno' }), {
      status: 500, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
    });
  }
});
