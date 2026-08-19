const { google } = require('googleapis');

const CLIENT_ID = process.env.GMAIL_CLIENT_ID;
const CLIENT_SECRET = process.env.GMAIL_CLIENT_SECRET;
const REFRESH_TOKEN = process.env.GMAIL_REFRESH_TOKEN;
const EMAIL_USER = process.env.EMAIL_USER;

const REDIRECT_URI = 'https://developers.google.com/oauthplayground';

console.log('[EMAIL] Config -> CLIENT_ID:', CLIENT_ID ? 'OK' : 'FALTA',
            '| CLIENT_SECRET:', CLIENT_SECRET ? 'OK' : 'FALTA',
            '| REFRESH_TOKEN:', REFRESH_TOKEN ? 'OK' : 'FALTA',
            '| EMAIL_USER:', EMAIL_USER || 'FALTA');

const oAuth2Client = new google.auth.OAuth2(CLIENT_ID, CLIENT_SECRET, REDIRECT_URI);
oAuth2Client.setCredentials({ refresh_token: REFRESH_TOKEN });

// Arma el mensaje en formato RFC 2822 y lo codifica en base64url (lo que pide la Gmail API)
function crearMensaje(destinatario, remitente, asunto, html) {
  const mensaje = [
    `From: Find Your Self <${remitente}>`,
    `To: ${destinatario}`,
    `Subject: =?UTF-8?B?${Buffer.from(asunto).toString('base64')}?=`,
    'MIME-Version: 1.0',
    'Content-Type: text/html; charset=UTF-8',
    '',
    html,
  ].join('\n');

  return Buffer.from(mensaje)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

async function enviarCodigoVerificacion(correoDestino, codigo) {
  console.log('[EMAIL] Intentando enviar codigo a:', correoDestino);
  try {
    // Envia por la Gmail API pura (HTTPS) — Render NO bloquea HTTPS
    const gmail = google.gmail({ version: 'v1', auth: oAuth2Client });

    const html = `
      <div style="font-family: Georgia, serif; max-width: 500px; margin: auto; padding: 40px; background-color: #faf6f0; border-radius: 12px;">
        <h2 style="color: #b8956a; letter-spacing: 4px; text-align: center;">FIND YOUR SELF</h2>
        <p style="color: #3d2f22; text-align: center; font-size: 14px;">Joyeria artesanal unica</p>
        <hr style="border: 1px solid #d4b896; margin: 24px 0;">
        <p style="color: #3d2f22; font-size: 16px;">Tu codigo de verificacion es:</p>
        <div style="background-color: #e8ddd0; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0;">
          <h1 style="color: #8a6840; letter-spacing: 10px; font-size: 36px; margin: 0;">${codigo}</h1>
        </div>
        <p style="color: #7a6150; font-size: 13px;">Este codigo expira en 10 minutos.</p>
        <p style="color: #7a6150; font-size: 13px;">Si no solicitaste este codigo, ignora este mensaje.</p>
        <hr style="border: 1px solid #d4b896; margin: 24px 0;">
        <p style="color: #b8956a; text-align: center; font-size: 12px; letter-spacing: 2px;">FIND YOUR SELF © 2025</p>
      </div>
    `;

    const raw = crearMensaje(
      correoDestino,
      EMAIL_USER,
      'Codigo de verificacion - Find Your Self',
      html
    );

    const resultado = await gmail.users.messages.send({
      userId: 'me',
      requestBody: { raw },
    });

    console.log('[EMAIL] Correo enviado OK. id:', resultado && resultado.data ? resultado.data.id : '(sin id)');
  } catch (err) {
    console.error('[EMAIL] ERROR al enviar:', err && err.message ? err.message : err);
    throw err;
  }
}

module.exports = { enviarCodigoVerificacion };