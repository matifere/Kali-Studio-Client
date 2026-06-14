// Manda el recordatorio "tu clase es en 1 hora" a cada reserva confirmada.
// La invoca el job programado send_class_reminders() (pg_cron -> pg_net), NO el
// cliente. Por eso valida un secreto compartido en vez de JWT (reusa el mismo
// WAITLIST_WEBHOOK_SECRET que send-waitlist-email).
//
// Deploy:  supabase functions deploy send-class-reminder --no-verify-jwt
// Secrets: SENDGRID_API_KEY, EMAIL_FROM, EMAIL_FROM_NAME, WAITLIST_WEBHOOK_SECRET
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

interface Payload {
  email: string;
  name?: string;
  class_name: string;
  date: string; // ya formateada: DD/MM/YYYY
  time: string; // ya formateada: HH:MM
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

  const { email, name, class_name, date, time } = payload;
  if (!email || !class_name || !date || !time) {
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
  const subject = `Recordatorio: ${class_name} en 1 hora`;
  const html = `
    <div style="font-family: Arial, sans-serif; font-size: 15px; color: #1a1a1a; line-height: 1.5;">
      <p>${saludo}</p>
      <p>Te recordamos que tu clase empieza en aproximadamente <strong>1 hora</strong>:</p>
      <table style="margin: 16px 0; border-collapse: collapse;">
        <tr><td style="padding: 4px 12px 4px 0; color: #666;">Clase</td><td style="padding: 4px 0;"><strong>${class_name}</strong></td></tr>
        <tr><td style="padding: 4px 12px 4px 0; color: #666;">Fecha</td><td style="padding: 4px 0;"><strong>${date}</strong></td></tr>
        <tr><td style="padding: 4px 12px 4px 0; color: #666;">Hora</td><td style="padding: 4px 0;"><strong>${time} hs</strong></td></tr>
      </table>
      <p>Si no podés asistir, cancelá desde la app para liberar tu lugar a la lista de espera.</p>
      <p style="color: #888; font-size: 13px; margin-top: 24px;">Este es un mensaje automático, no respondas a este correo.</p>
    </div>`;
  const text = `${saludo}\n\nTe recordamos que tu clase empieza en aproximadamente 1 hora:\n\n`
    + `Clase: ${class_name}\nFecha: ${date}\nHora: ${time} hs\n\n`
    + `Si no podés asistir, cancelá desde la app para liberar tu lugar a la lista de espera.`;

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
