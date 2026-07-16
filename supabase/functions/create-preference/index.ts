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
  console.log('request:', req.method, req.url, 'origin:', req.headers.get('Origin'));

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

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Tu sesión expiró. Volvé a iniciar sesión.' }), {
        status: 401, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
      });
    }

    const { plan_id } = await req.json();
    if (!plan_id) {
      return new Response(JSON.stringify({ error: 'No pudimos identificar el plan. Actualizá la pantalla e intentá de nuevo.' }), {
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
      return new Response(JSON.stringify({ error: 'Este plan ya no está disponible. Actualizá la pantalla y elegí otro.' }), {
        status: 404, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
      });
    }

    if (profile?.institution_id && plan.institution_id !== profile.institution_id) {
      return new Response(JSON.stringify({ error: 'Este plan no está disponible para tu estudio.' }), {
        status: 403, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
      });
    }

    const institutionId = plan.institution_id ?? profile?.institution_id;
    console.log('institutionId:', institutionId);

    // ── Determine payment method ──────────────────────────────────────────────
    let mpAccessToken: string | null = null;
    let transferAlias: string | null = null;

    if (institutionId) {
      // 1. Get MP token or alias from institutions table
      const { data: inst } = await supabase
        .from('institutions')
        .select('mp_token_secret_name, payment_alias')
        .eq('id', institutionId)
        .maybeSingle();
      
      if (inst?.mp_token_secret_name && (inst.mp_token_secret_name.startsWith('APP_USR-') || inst.mp_token_secret_name.startsWith('TEST-'))) {
        console.log('Using raw token from mp_token_secret_name');
        mpAccessToken = inst.mp_token_secret_name;
      }

      if (!mpAccessToken) {
        transferAlias = inst?.payment_alias ?? null;
        console.log('payment_alias present:', !!transferAlias);
      }
    }

    if (!mpAccessToken && !transferAlias) {
      console.error('No payment method found for institutionId:', institutionId);
      return new Response(JSON.stringify({ error: 'Tu estudio todavía no configuró un método de pago. Consultá con tu instructor.' }), {
        status: 503, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
      });
    }

    // ── Create or reuse pending subscription + payment (both paths) ──────────
    // Reabrir la pantalla de pago no debe acumular filas: si ya hay una
    // suscripción pendiente de este usuario para este plan, reusamos esa y su
    // pago pendiente en vez de insertar duplicados.
    const toDate = (d: Date) => d.toISOString().substring(0, 10);
    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + 30);

    let subscriptionId: string | null = null;
    let paymentId: string | null = null;
    let createdSubscription = false;
    let createdPayment = false;

    const { data: existingSub } = await supabase
      .from('subscriptions')
      .select('id')
      .eq('user_id', user.id)
      .eq('plan_id', plan.id)
      .eq('status', 'pending')
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (existingSub) {
      subscriptionId = existingSub.id;
      await supabase.from('subscriptions')
        .update({ start_date: toDate(startDate), end_date: toDate(endDate) })
        .eq('id', subscriptionId);

      const { data: existingPayment } = await supabase
        .from('payments')
        .select('id')
        .eq('subscription_id', subscriptionId)
        .eq('status', 'pending')
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (existingPayment) {
        paymentId = existingPayment.id;
        // por si cambió el precio del plan desde la última vez
        await supabase.from('payments')
          .update({ amount: Number(plan.price), currency: plan.currency ?? 'ARS' })
          .eq('id', paymentId);
      }
    }

    if (!subscriptionId) {
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
        return new Response(JSON.stringify({ error: 'No pudimos registrar tu suscripción. Intentá de nuevo en unos segundos.' }), {
          status: 500, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
        });
      }
      subscriptionId = subscription.id;
      createdSubscription = true;
    }

    if (!paymentId) {
      const { data: paymentRecord, error: paymentInsertError } = await supabase
        .from('payments')
        .insert({
          user_id: user.id,
          subscription_id: subscriptionId,
          amount: Number(plan.price),
          currency: plan.currency ?? 'ARS',
          status: 'pending',
          institution_id: institutionId ?? null,
        })
        .select('id')
        .single();

      if (paymentInsertError || !paymentRecord) {
        console.error('Payment insert error:', paymentInsertError?.message);
        if (createdSubscription) {
          await supabase.from('subscriptions').delete().eq('id', subscriptionId);
        }
        return new Response(JSON.stringify({ error: 'No pudimos registrar el pago. Intentá de nuevo en unos segundos.' }), {
          status: 500, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
        });
      }
      paymentId = paymentRecord.id;
      createdPayment = true;
    }

    console.log('subscription:', subscriptionId, 'payment:', paymentId, 'reused:', !createdSubscription);

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
        marketplace_fee: Number((Number(plan.price) * 0.05).toFixed(2)),
        external_reference: subscriptionId,
        back_urls: {
          success: 'https://turnos.argity.com',
          failure: 'https://turnos.argity.com',
          pending: 'https://turnos.argity.com',
        },
        auto_return: 'approved',
        notification_url: `${Deno.env.get('SUPABASE_URL')}/functions/v1/mp-client-webhook?institution_id=${institutionId}`,
      }),
    });

    if (!mpResponse.ok) {
      const mpErr = await mpResponse.text();
      console.error('MP error:', mpErr);
      // solo borramos lo creado en esta llamada; las filas reusadas quedan
      if (createdPayment) {
        await supabase.from('payments').delete().eq('id', paymentId);
      }
      if (createdSubscription) {
        await supabase.from('subscriptions').delete().eq('id', subscriptionId);
      }
      return new Response(JSON.stringify({ error: 'No pudimos generar el link de pago. Intentá de nuevo en unos segundos.' }), {
        status: 500, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
      });
    }

    const preference = await mpResponse.json();

    await supabase.from('payments')
      .update({ preference_id: preference.id })
      .eq('id', paymentId);

    return new Response(JSON.stringify({ url: preference.init_point }), {
      status: 200, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
    });

  } catch (e) {
    console.error(e);
    return new Response(JSON.stringify({ error: 'Algo salió mal de nuestro lado. Intentá de nuevo en unos segundos.' }), {
      status: 500, headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
    });
  }
});
