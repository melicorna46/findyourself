const { Resend } = require('resend');

// La API key se lee de la variable de entorno RESEND_API_KEY (se configura en Render).
const resend = new Resend(process.env.RESEND_API_KEY);

async function enviarCodigoVerificacion(correoDestino, codigo) {
  await resend.emails.send({
    // Remitente: en el plan gratis sin dominio propio, se usa el de prueba de Resend.
    from: 'Find Your Self <onboarding@resend.dev>',
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