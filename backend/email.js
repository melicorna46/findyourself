const nodemailer = require('nodemailer');
const { google } = require('googleapis');

const CLIENT_ID = process.env.GMAIL_CLIENT_ID;
const CLIENT_SECRET = process.env.GMAIL_CLIENT_SECRET;
const REFRESH_TOKEN = process.env.GMAIL_REFRESH_TOKEN;
const EMAIL_USER = process.env.EMAIL_USER;

const REDIRECT_URI = 'https://developers.google.com/oauthplayground';

// Aviso en el arranque si falta alguna variable (aparece en los logs de Render)
console.log('[EMAIL] Config -> CLIENT_ID:', CLIENT_ID ? 'OK' : 'FALTA',
            '| CLIENT_SECRET:', CLIENT_SECRET ? 'OK' : 'FALTA',
            '| REFRESH_TOKEN:', REFRESH_TOKEN ? 'OK' : 'FALTA',
            '| EMAIL_USER:', EMAIL_USER || 'FALTA');

const oAuth2Client = new google.auth.OAuth2(CLIENT_ID, CLIENT_SECRET, REDIRECT_URI);
oAuth2Client.setCredentials({ refresh_token: REFRESH_TOKEN });

// Envuelve una promesa con un limite de tiempo para que no cuelgue eternamente
function conTimeout(promesa, ms, mensaje) {
  return Promise.race([
    promesa,
    new Promise((_, reject) => setTimeout(() => reject(new Error(mensaje)), ms)),
  ]);
}

async function enviarCodigoVerificacion(correoDestino, codigo) {
  console.log('[EMAIL] Intentando enviar codigo a:', correoDestino);
  try {
    // Pide un access token, con limite de 15 seg
    const accessToken = await conTimeout(
      oAuth2Client.getAccessToken(),
      15000,
      'Timeout pidiendo access token a Google'
    );
    console.log('[EMAIL] Access token obtenido:', accessToken && accessToken.token ? 'OK' : 'VACIO');

    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        type: 'OAuth2',
        user: EMAIL_USER,
        clientId: CLIENT_ID,
        clientSecret: CLIENT_SECRET,
        refreshToken: REFRESH_TOKEN,
        accessToken: accessToken.token,
      },
    });

    const info = await conTimeout(
      transporter.sendMail({
        from: `Find Your Self <${EMAIL_USER}>`,
        to: correoDestino,
        subject: 'Codigo de verificacion - Find Your Self',
        html: `
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
        `,
      }),
      20000,
      'Timeout enviando el correo'
    );
    console.log('[EMAIL] Correo enviado OK:', info && info.messageId ? info.messageId : '(sin id)');
  } catch (err) {
    console.error('[EMAIL] ERROR al enviar:', err && err.message ? err.message : err);
    throw err; // relanza para que el registro sepa que fallo
  }
}

module.exports = { enviarCodigoVerificacion };d