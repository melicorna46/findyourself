const nodemailer = require('nodemailer');
const { google } = require('googleapis');

// Credenciales de Google (se leen de variables de entorno en Render).
const CLIENT_ID = process.env.GMAIL_CLIENT_ID;
const CLIENT_SECRET = process.env.GMAIL_CLIENT_SECRET;
const REFRESH_TOKEN = process.env.GMAIL_REFRESH_TOKEN;
const EMAIL_USER = process.env.EMAIL_USER; // el correo que envia (ej. pmisvo@gmail.com)

const REDIRECT_URI = 'https://developers.google.com/oauthplayground';

const oAuth2Client = new google.auth.OAuth2(CLIENT_ID, CLIENT_SECRET, REDIRECT_URI);
oAuth2Client.setCredentials({ refresh_token: REFRESH_TOKEN });

async function enviarCodigoVerificacion(correoDestino, codigo) {
  // Genera un token de acceso fresco usando el refresh token
  const accessToken = await oAuth2Client.getAccessToken();

  // Envia por la Gmail API (HTTPS) usando Nodemailer con OAuth2
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

  await transporter.sendMail({
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
  });
}

module.exports = { enviarCodigoVerificacion };