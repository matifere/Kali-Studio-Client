// Manda el aviso "tu plan vence en una semana" a cada alumno con suscripcion
// activa cuyo end_date cae dentro de 7 dias. La invoca el job programado
// send_payment_reminders() (pg_cron -> pg_net), NO el cliente. Por eso valida un
// secreto compartido en vez de JWT (reusa el mismo WAITLIST_WEBHOOK_SECRET que
// send-waitlist-email y el viejo recordatorio de clases).
//
// Deploy:  supabase functions deploy send-payment-reminder --no-verify-jwt
// Secrets: SENDGRID_API_KEY, EMAIL_FROM, EMAIL_FROM_NAME, WAITLIST_WEBHOOK_SECRET
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

interface Payload {
  email: string;
  name?: string;
  plan_name: string;
  end_date: string; // ya formateada: DD/MM/YYYY
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  // Auth: secreto compartido con el job (no JWT de usuario)
  const expectedSecret = Deno.env.get('WAITLIST_WEBHOOK_SECRET');
  if (!expectedSecret || req.headers.get('x-webhook-secret') !== expectedSecret) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), {
      status: 401, headers: { 'Content-Type': 'application/json' },
    });
  }

  let payload: Payload;
  try {
    payload = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: 'invalid_json' }), {
      status: 400, headers: { 'Content-Type': 'application/json' },
    });
  }

  const { email, name, plan_name, end_date } = payload;
  if (!email || !plan_name || !end_date) {
    return new Response(JSON.stringify({ error: 'missing_fields' }), {
      status: 400, headers: { 'Content-Type': 'application/json' },
    });
  }

  const apiKey = Deno.env.get('SENDGRID_API_KEY');
  const from = Deno.env.get('EMAIL_FROM') ?? 'Servicios@argity.com';
  const fromName = Deno.env.get('EMAIL_FROM_NAME') ?? 'Argity';
  if (!apiKey) {
    console.error('Falta SENDGRID_API_KEY');
    return new Response(JSON.stringify({ error: 'not_configured' }), {
      status: 500, headers: { 'Content-Type': 'application/json' },
    });
  }

  const saludo = name && name.trim().length > 0 ? `Hola ${name},` : 'Hola,';
  const subject = `Tu plan ${plan_name} vence en una semana`;
  const html = `
    <div style="font-family: Arial, sans-serif; font-size: 15px; color: #1a1a1a; line-height: 1.5;">
      <p>${saludo}</p>
      <p>Te avisamos que tu plan está por vencer <strong>en una semana</strong>:</p>
      <table style="margin: 16px 0; border-collapse: collapse;">
        <tr><td style="padding: 4px 12px 4px 0; color: #666;">Plan</td><td style="padding: 4px 0;"><strong>${plan_name}</strong></td></tr>
        <tr><td style="padding: 4px 12px 4px 0; color: #666;">Vence el</td><td style="padding: 4px 0;"><strong>${end_date}</strong></td></tr>
      </table>
      <p>Renová tu plan para seguir reservando clases sin interrupciones.</p>
      <p style="color: #888; font-size: 13px; margin-top: 24px;">Este es un mensaje automático, no respondas a este correo.</p>
    </div>`;
  const text = `${saludo}\n\nTe avisamos que tu plan está por vencer en una semana:\n\n`
    + `Plan: ${plan_name}\nVence el: ${end_date}\n\n`
    + `Renová tu plan para seguir reservando clases sin interrupciones.`;

  const res = await fetch('https://api.sendgrid.com/v3/mail/send', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      personalizations: [{ to: [{ email, name: name || undefined }] }],
      from: { email: from, name: fromName },
      subject,
      content: [
        { type: 'text/plain', value: text },
        { type: 'text/html', value: html },
      ],
    }),
  });

  if (res.status !== 202) {
    const detail = await res.text();
    console.error(`SendGrid fallo: ${res.status} ${detail}`);
    return new Response(JSON.stringify({ error: 'send_failed', status: res.status }), {
      status: 502, headers: { 'Content-Type': 'application/json' },
    });
  }

  return new Response(JSON.stringify({ ok: true }), {
    status: 200, headers: { 'Content-Type': 'application/json' },
  });
});
