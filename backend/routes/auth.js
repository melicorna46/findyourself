// Importacion de librerias necesarias
const express = require('express');
const router = express.Router();
const pool = require('../db'); // conexion a PostgreSQL
const bcrypt = require('bcrypt'); // para encriptar contrasenas
const jwt = require('jsonwebtoken'); // para generar tokens de sesion
const speakeasy = require('speakeasy'); // para generar el OTP de Google Authenticator
const { enviarCodigoVerificacion } = require('../email'); // para enviar correos reales
const axios = require('axios'); // para llamar al TSE (API a API)
const TSE_URL = 'http://localhost:5001'; // URL de la institucion TSE (externa)

// Clave secreta para firmar los tokens JWT
const JWT_SECRET = 'findyourself_secret_2025';
// Numero de veces que bcrypt encripta la contrasena (mas alto = mas seguro)
const SALT_ROUNDS = 10;

// ============================================================
// POLITICA DE PASSWORD
// Valida que la contrasena cumpla con los requisitos minimos
// ============================================================
function validarPassword(password) {
  const errores = [];
  if (password.length < 8) errores.push('Minimo 8 caracteres');
  if (!/[A-Z]/.test(password)) errores.push('Al menos una mayuscula');
  if (!/[a-z]/.test(password)) errores.push('Al menos una minuscula');
  if (!/[0-9]/.test(password)) errores.push('Al menos un numero');
  if (!/[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]/.test(password)) errores.push('Al menos un simbolo');
  return errores;
}

// ============================================================
// POLITICA DE USUARIO
// Valida que el nombre de usuario cumpla con los requisitos minimos
// ============================================================
function validarUsuario(usuario) {
  const errores = [];
  if (usuario.length < 10) errores.push('Minimo 10 caracteres');
  if (!/[A-Z]/.test(usuario)) errores.push('Al menos una mayuscula');
  if (!/[a-z]/.test(usuario)) errores.push('Al menos una minuscula');
  if (!/[0-9]/.test(usuario)) errores.push('Al menos un numero');
  return errores;
}

// ============================================================
// AUDITORIA
// Guarda en la BD cada accion importante que ocurre en el sistema
// ============================================================
async function registrarAuditoria(usuarioId, accion, detalle, ip, exitoso) {
  try {
    await pool.query(
      `INSERT INTO auditoria (usuario_id, accion, detalle, ip, exitoso)
       VALUES ($1, $2, $3, $4, $5)`,
      [usuarioId, accion, detalle, ip, exitoso]
    );
  } catch (error) {
    console.error('Error auditoria:', error);
  }
}

// ============================================================
// CREAR USUARIO — POST /auth/registro
// Recibe los datos del formulario, valida politicas,
// encripta la contrasena y envia token de verificacion al correo
// ============================================================
router.post('/registro', async (req, res) => {
  try {
    const { nombre, apellido, correo, nombre_usuario, contrasena, pregunta_seguridad, respuesta_seguridad } = req.body;

    // Verifica que el usuario cumpla la politica (min 10 chars, may, min, num)
    const erroresUsuario = validarUsuario(nombre_usuario);
    if (erroresUsuario.length > 0) {
      return res.status(400).json({ error: 'Politica de usuario', detalle: erroresUsuario });
    }

    // Verifica que la contrasena cumpla la politica (min 8 chars, may, min, num, simbolo)
    const erroresPassword = validarPassword(contrasena);
    if (erroresPassword.length > 0) {
      return res.status(400).json({ error: 'Politica de password', detalle: erroresPassword });
    }

    // Verifica que el correo o usuario no existan ya en la BD
    const existe = await pool.query(
      'SELECT id FROM usuarios WHERE correo = $1 OR nombre_usuario = $2',
      [correo, nombre_usuario]
    );
    if (existe.rows.length > 0) {
      return res.status(400).json({ error: 'El correo o usuario ya existe' });
    }

    // Encriptacion con bcrypt — la contrasena nunca se guarda en texto plano
    const hash = await bcrypt.hash(contrasena, SALT_ROUNDS);
    // Encriptacion de la respuesta de seguridad tambien con bcrypt
    const respuestaHash = await bcrypt.hash(respuesta_seguridad.toLowerCase(), SALT_ROUNDS);
    // Genera el secret unico para Google Authenticator usando speakeasy
    const otpSecret = speakeasy.generateSecret({ name: `FindYourSelf:${correo}` });

    // La contrasena tiene vigencia de 90 dias
    const passwordExpira = new Date();
    passwordExpira.setDate(passwordExpira.getDate() + 90);

    // Genera el token de verificacion de correo — numero aleatorio de 6 digitos
    const tokenCorreo = Math.floor(100000 + Math.random() * 900000).toString();
    // El token expira en 10 minutos
    const tokenExpira = new Date();
    tokenExpira.setMinutes(tokenExpira.getMinutes() + 10);

    // Guarda el usuario en la BD con todos sus datos
    const resultado = await pool.query(
      `INSERT INTO usuarios (nombre, apellido, correo, nombre_usuario, contrasena_hash, 
        pregunta_seguridad, respuesta_seguridad, otp_secret, password_expira,
        token_correo, token_correo_expira, correo_verificado)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, false) RETURNING id`,
      [nombre, apellido, correo, nombre_usuario, hash, pregunta_seguridad,
       respuestaHash, otpSecret.base32, passwordExpira, tokenCorreo, tokenExpira]
    );

    const usuarioId = resultado.rows[0].id;

    // Envia el token de 6 digitos al correo real del usuario con Nodemailer
    await enviarCodigoVerificacion(correo, tokenCorreo);
    // Registra la accion en la tabla de auditoria
    await registrarAuditoria(usuarioId, 'REGISTRO', 'Usuario creado, pendiente verificacion de correo', req.ip, true);

    res.json({
      mensaje: 'Usuario creado. Revisa tu correo para verificar tu cuenta.',
      usuarioId,
      otpSecret: otpSecret.base32,
      otpUrl: otpSecret.otpauth_url,
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============================================================
// VERIFICAR CORREO — POST /auth/verificar-correo
// El usuario ingresa el token de 6 digitos que llego a su correo
// Si es correcto, su cuenta queda verificada y puede iniciar sesion
// ============================================================
router.post('/verificar-correo', async (req, res) => {
  try {
    const { usuarioId, token } = req.body;

    // Busca el usuario en la BD
    const resultado = await pool.query('SELECT * FROM usuarios WHERE id = $1', [usuarioId]);
    const usuario = resultado.rows[0];

    // Verifica que el token ingresado sea el mismo que se envio al correo
    if (!usuario.token_correo || usuario.token_correo !== token) {
      return res.status(401).json({ error: 'Codigo incorrecto' });
    }

    // Verifica que el token no haya expirado (tiene 10 minutos de vida)
    if (new Date() > new Date(usuario.token_correo_expira)) {
      return res.status(401).json({ error: 'Codigo expirado, registrate de nuevo' });
    }

    // Marca el correo como verificado y elimina el token usado
    await pool.query(
      'UPDATE usuarios SET correo_verificado = true, token_correo = NULL, token_correo_expira = NULL WHERE id = $1',
      [usuarioId]
    );

    // Registra en auditoria que el correo fue verificado
    await registrarAuditoria(usuarioId, 'CORREO_VERIFICADO', 'Correo verificado exitosamente', req.ip, true);

    res.json({
      mensaje: 'Correo verificado exitosamente',
      usuarioId,
      otpSecret: usuario.otp_secret,
      otpUrl: `otpauth://totp/FindYourSelf:${usuario.correo}?secret=${usuario.otp_secret}`,
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============================================================
// LOGIN — POST /auth/login
// Verifica usuario y contrasena, maneja bloqueos e intentos fallidos
// Si todo es correcto devuelve los datos para el doble factor
// ============================================================
router.post('/login', async (req, res) => {
  try {
    const { nombre_usuario, contrasena } = req.body;

    // Busca el usuario en la BD por su nombre de usuario
    const resultado = await pool.query(
      'SELECT * FROM usuarios WHERE nombre_usuario = $1',
      [nombre_usuario]
    );

    // Si no existe devuelve error generico por seguridad
    if (resultado.rows.length === 0) {
      return res.status(401).json({ error: 'Usuario o password incorrectos' });
    }

    const usuario = resultado.rows[0];

    // Verifica que el usuario haya confirmado su correo antes de poder entrar
    if (!usuario.correo_verificado) {
      return res.status(403).json({ error: 'Debes verificar tu correo antes de iniciar sesion' });
    }

    // Verifica si la cuenta esta bloqueada por intentos fallidos
    if (usuario.bloqueado) {
      const ahora = new Date();
      if (usuario.bloqueado_hasta && ahora < new Date(usuario.bloqueado_hasta)) {
        // Calcula cuantos segundos faltan para desbloquear
        const segundosRestantes = Math.ceil((new Date(usuario.bloqueado_hasta) - ahora) / 1000);
        const mensaje = segundosRestantes < 60
          ? `Usuario bloqueado. Intenta en ${segundosRestantes} segundos`
          : `Usuario bloqueado. Intenta en ${Math.ceil(segundosRestantes / 60)} minutos`;
        await registrarAuditoria(usuario.id, 'LOGIN_BLOQUEADO', mensaje, req.ip, false);
        return res.status(403).json({ error: mensaje });
      } else {
        // Si ya paso el tiempo de bloqueo, desbloquea automaticamente
        await pool.query('UPDATE usuarios SET bloqueado = false, intentos_fallidos = 0 WHERE id = $1', [usuario.id]);
      }
    }

    // Compara la contrasena ingresada con el hash guardado en BD usando bcrypt
    const passwordValido = await bcrypt.compare(contrasena, usuario.contrasena_hash);

    if (!passwordValido) {
      const intentos = usuario.intentos_fallidos + 1;

      // Si llega a 3 intentos fallidos bloquea la cuenta por 1 minuto
      if (intentos >= 3) {
        const bloqueadoHasta = new Date();
        bloqueadoHasta.setMinutes(bloqueadoHasta.getMinutes() + 1);
        await pool.query(
          'UPDATE usuarios SET intentos_fallidos = $1, bloqueado = true, bloqueado_hasta = $2 WHERE id = $3',
          [intentos, bloqueadoHasta, usuario.id]
        );
        await registrarAuditoria(usuario.id, 'LOGIN_FALLIDO', 'Usuario bloqueado por 3 intentos fallidos', req.ip, false);
        return res.status(403).json({ error: 'Usuario bloqueado por 1 minuto por 3 intentos fallidos' });
      }

      // Si no llego a 3 intentos, suma el intento fallido y avisa cuantos van
      await pool.query('UPDATE usuarios SET intentos_fallidos = $1 WHERE id = $2', [intentos, usuario.id]);
      await registrarAuditoria(usuario.id, 'LOGIN_FALLIDO', `Intento ${intentos} de 3`, req.ip, false);
      return res.status(401).json({ error: `Password incorrecto. Intento ${intentos} de 3` });
    }

    // Verifica si la contrasena ha vencido (cada 90 dias)
    if (usuario.password_expira && new Date() > new Date(usuario.password_expira)) {
      return res.status(403).json({ error: 'PASSWORD_EXPIRADO', usuarioId: usuario.id });
    }

    // Reset de intentos fallidos al hacer login exitoso
    await pool.query(
      'UPDATE usuarios SET intentos_fallidos = 0, ultimo_login = NOW() WHERE id = $1',
      [usuario.id]
    );

    // Registra el login exitoso en auditoria
    await registrarAuditoria(usuario.id, 'LOGIN_EXITOSO', 'Login correcto, pendiente OTP', req.ip, true);

    // Devuelve los datos necesarios para el doble factor (OTP)
    res.json({
      mensaje: 'Credenciales correctas',
      usuarioId: usuario.id,
      nombre: usuario.nombre,
      otpSecret: usuario.otp_secret,
      otpUrl: `otpauth://totp/FindYourSelf:${usuario.correo}?secret=${usuario.otp_secret}`,
      requiereOtp: true,
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============================================================
// VERIFICAR OTP GOOGLE AUTHENTICATOR — POST /auth/verificar-otp
// Verifica el codigo de 6 digitos generado por Google Authenticator
// Si es correcto genera el JWT de sesion
// ============================================================
router.post('/verificar-otp', async (req, res) => {
  try {
    const { usuarioId, codigo } = req.body;

    const resultado = await pool.query('SELECT * FROM usuarios WHERE id = $1', [usuarioId]);
    const usuario = resultado.rows[0];

    // speakeasy compara el codigo ingresado con el que deberia mostrar Google Authenticator
    // window: 1 permite un margen de 30 segundos antes y despues
    const valido = speakeasy.totp.verify({
      secret: usuario.otp_secret,
      encoding: 'base32',
      token: codigo,
      window: 1,
    });

    if (!valido) {
      await registrarAuditoria(usuarioId, 'OTP_FALLIDO', 'Codigo OTP incorrecto', req.ip, false);
      return res.status(401).json({ error: 'Codigo OTP incorrecto' });
    }

    // Si el OTP es valido genera el JWT con duracion de 8 horas
    const token = jwt.sign({ usuarioId: usuario.id, nombre: usuario.nombre }, JWT_SECRET, { expiresIn: '8h' });
    await registrarAuditoria(usuarioId, 'LOGIN_COMPLETO', 'Login con OTP exitoso', req.ip, true);
    res.json({ mensaje: 'Login exitoso', token, nombre: usuario.nombre });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============================================================
// RECUPERAR PASSWORD (metodo antiguo) — POST /auth/recuperar
// Verifica la respuesta de seguridad y cambia la contrasena directamente
// ============================================================
router.post('/recuperar', async (req, res) => {
  try {
    const { nombre_usuario, respuesta_seguridad, nueva_contrasena } = req.body;

    const resultado = await pool.query(
      'SELECT * FROM usuarios WHERE nombre_usuario = $1',
      [nombre_usuario]
    );

    if (resultado.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    const usuario = resultado.rows[0];

    // Compara la respuesta ingresada con el hash guardado en BD
    const respuestaValida = await bcrypt.compare(
      respuesta_seguridad.toLowerCase(),
      usuario.respuesta_seguridad
    );

    if (!respuestaValida) {
      await registrarAuditoria(usuario.id, 'RECUPERACION_FALLIDA', 'Respuesta de seguridad incorrecta', req.ip, false);
      return res.status(401).json({ error: 'Respuesta de seguridad incorrecta' });
    }

    // Valida que la nueva contrasena cumpla la politica
    const errores = validarPassword(nueva_contrasena);
    if (errores.length > 0) {
      return res.status(400).json({ error: 'Politica de password', detalle: errores });
    }

    // Encripta la nueva contrasena y actualiza la vigencia a 90 dias
    const hash = await bcrypt.hash(nueva_contrasena, SALT_ROUNDS);
    const passwordExpira = new Date();
    passwordExpira.setDate(passwordExpira.getDate() + 90);

    await pool.query(
      'UPDATE usuarios SET contrasena_hash = $1, password_expira = $2, intentos_fallidos = 0, bloqueado = false WHERE id = $3',
      [hash, passwordExpira, usuario.id]
    );

    await registrarAuditoria(usuario.id, 'RECUPERACION_EXITOSA', 'Password actualizado exitosamente', req.ip, true);
    res.json({ mensaje: 'Password actualizado exitosamente' });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============================================================
// VER AUDITORIA — GET /auth/auditoria/:usuarioId
// Devuelve las ultimas 50 acciones registradas del usuario
// ============================================================
router.get('/auditoria/:usuarioId', async (req, res) => {
  try {
    const { usuarioId } = req.params;
    const resultado = await pool.query(
      `SELECT accion, detalle, ip, exitoso, fecha 
       FROM auditoria 
       WHERE usuario_id = $1 
       ORDER BY fecha DESC 
       LIMIT 50`,
      [usuarioId]
    );
    res.json(resultado.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============================================================
// ACTIVAR OTP — POST /auth/activar-otp
// Verifica el codigo de Google Authenticator y activa el doble factor
// ============================================================
router.post('/activar-otp', async (req, res) => {
  try {
    const { usuarioId, codigo } = req.body;

    const resultado = await pool.query('SELECT * FROM usuarios WHERE id = $1', [usuarioId]);
    const usuario = resultado.rows[0];

    // Verifica el codigo con speakeasy para confirmar que Google Authenticator esta bien configurado
    const valido = speakeasy.totp.verify({
      secret: usuario.otp_secret,
      encoding: 'base32',
      token: codigo,
      window: 1,
    });

    if (!valido) {
      return res.status(401).json({ error: 'Codigo OTP incorrecto' });
    }

    // Marca el OTP como activo en la BD
    await pool.query('UPDATE usuarios SET otp_activo = true WHERE id = $1', [usuarioId]);
    await registrarAuditoria(usuarioId, 'OTP_ACTIVADO', 'Doble factor activado', req.ip, true);
    res.json({ mensaje: 'Doble factor activado exitosamente' });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============================================================
// GENERAR OTP PROPIO — POST /auth/generar-otp-app
// Genera un codigo de 6 digitos aleatorio propio de la app
// Lo guarda en BD con expiracion de 5 minutos
// ============================================================
router.post('/generar-otp-app', async (req, res) => {
  try {
    const { usuarioId } = req.body;

    // Math.random genera un numero entre 0 y 1, se multiplica para obtener 6 digitos
    const codigo = Math.floor(100000 + Math.random() * 900000).toString();
    // El codigo expira en 5 minutos
    const expira = new Date();
    expira.setMinutes(expira.getMinutes() + 5);

    // Guarda el codigo y su expiracion en la BD
    await pool.query(
      'UPDATE usuarios SET otp_app = $1, otp_app_expira = $2 WHERE id = $3',
      [codigo, expira, usuarioId]
    );

    await registrarAuditoria(usuarioId, 'OTP_APP_GENERADO', 'Codigo OTP propio generado', req.ip, true);
    res.json({ mensaje: 'Codigo generado y enviado', codigo });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============================================================
// VERIFICAR OTP PROPIO — POST /auth/verificar-otp-app
// Verifica el codigo generado por la app, si es correcto genera el JWT
// ============================================================
router.post('/verificar-otp-app', async (req, res) => {
  try {
    const { usuarioId, codigo } = req.body;

    const resultado = await pool.query('SELECT * FROM usuarios WHERE id = $1', [usuarioId]);
    const usuario = resultado.rows[0];

    // Compara el codigo ingresado con el guardado en BD
    if (!usuario.otp_app || usuario.otp_app !== codigo) {
      await registrarAuditoria(usuarioId, 'OTP_APP_FALLIDO', 'Codigo OTP propio incorrecto', req.ip, false);
      return res.status(401).json({ error: 'Codigo incorrecto' });
    }

    // Verifica que el codigo no haya expirado (tiene 5 minutos de vida)
    if (new Date() > new Date(usuario.otp_app_expira)) {
      return res.status(401).json({ error: 'Codigo expirado, solicita uno nuevo' });
    }

    // Elimina el codigo usado para que no se pueda reutilizar
    await pool.query('UPDATE usuarios SET otp_app = NULL, otp_app_expira = NULL WHERE id = $1', [usuarioId]);

    // Genera el JWT de sesion con duracion de 8 horas
    const token = jwt.sign({ usuarioId: usuario.id, nombre: usuario.nombre }, JWT_SECRET, { expiresIn: '8h' });
    await registrarAuditoria(usuarioId, 'LOGIN_COMPLETO', 'Login con OTP de app exitoso', req.ip, true);
    res.json({ mensaje: 'Login exitoso', token, nombre: usuario.nombre });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============================================================
// OBTENER PREGUNTA DE SEGURIDAD — GET /auth/pregunta/:nombreUsuario
// Devuelve la pregunta de seguridad del usuario para el flujo de recuperacion
// ============================================================
router.get('/pregunta/:nombreUsuario', async (req, res) => {
  try {
    const { nombreUsuario } = req.params;
    const resultado = await pool.query(
      'SELECT pregunta_seguridad FROM usuarios WHERE nombre_usuario = $1',
      [nombreUsuario]
    );

    if (resultado.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    res.json({ pregunta: resultado.rows[0].pregunta_seguridad });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============================================================
// RECUPERAR CON TOKEN — POST /auth/recuperar-con-token
// Verifica la respuesta de seguridad y envia un token al correo
// El usuario luego usa ese token para cambiar su contrasena
// ============================================================
router.post('/recuperar-con-token', async (req, res) => {
  try {
    const { nombre_usuario, respuesta_seguridad } = req.body;

    const resultado = await pool.query(
      'SELECT * FROM usuarios WHERE nombre_usuario = $1',
      [nombre_usuario]
    );

    if (resultado.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    const usuario = resultado.rows[0];

    // Verifica la respuesta de seguridad con bcrypt
    const respuestaValida = await bcrypt.compare(
      respuesta_seguridad.toLowerCase(),
      usuario.respuesta_seguridad
    );

    if (!respuestaValida) {
      await registrarAuditoria(usuario.id, 'RECUPERACION_FALLIDA', 'Respuesta de seguridad incorrecta', req.ip, false);
      return res.status(401).json({ error: 'Respuesta incorrecta' });
    }

    // Genera el token de recuperacion — numero aleatorio de 6 digitos
    const tokenRecuperacion = Math.floor(100000 + Math.random() * 900000).toString();
    // El token expira en 10 minutos
    const tokenExpira = new Date();
    tokenExpira.setMinutes(tokenExpira.getMinutes() + 10);

    // Guarda el token en la BD
    await pool.query(
      'UPDATE usuarios SET token_correo = $1, token_correo_expira = $2 WHERE id = $3',
      [tokenRecuperacion, tokenExpira, usuario.id]
    );

    // Envia el token al correo real del usuario con Nodemailer
    await enviarCodigoVerificacion(usuario.correo, tokenRecuperacion);
    await registrarAuditoria(usuario.id, 'RECUPERACION_TOKEN_ENVIADO', 'Token de recuperacion enviado al correo', req.ip, true);

    res.json({
      mensaje: 'Token enviado al correo',
      usuarioId: usuario.id,
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============================================================
// CAMBIAR PASSWORD CON TOKEN — POST /auth/cambiar-password
// El usuario ingresa el token recibido por correo y su nueva contrasena
// Si el token es valido y no expiro, actualiza la contrasena encriptada
// ============================================================
router.post('/cambiar-password', async (req, res) => {
  try {
    const { usuarioId, token, nueva_contrasena } = req.body;

    const resultado = await pool.query('SELECT * FROM usuarios WHERE id = $1', [usuarioId]);
    const usuario = resultado.rows[0];

    // Verifica que el token ingresado sea el mismo que se envio al correo
    if (!usuario.token_correo || usuario.token_correo !== token) {
      return res.status(401).json({ error: 'Token incorrecto' });
    }

    // Verifica que el token no haya expirado
    if (new Date() > new Date(usuario.token_correo_expira)) {
      return res.status(401).json({ error: 'Token expirado' });
    }

    // Valida que la nueva contrasena cumpla la politica
    const errores = validarPassword(nueva_contrasena);
    if (errores.length > 0) {
      return res.status(400).json({ error: 'Politica de password', detalle: errores });
    }

    // Encripta la nueva contrasena con bcrypt
    const hash = await bcrypt.hash(nueva_contrasena, SALT_ROUNDS);
    // Renueva la vigencia de la contrasena a 90 dias
    const passwordExpira = new Date();
    passwordExpira.setDate(passwordExpira.getDate() + 90);

    // Actualiza la contrasena, elimina el token usado y desbloquea la cuenta
    await pool.query(
      `UPDATE usuarios SET contrasena_hash = $1, password_expira = $2, 
       token_correo = NULL, token_correo_expira = NULL,
       intentos_fallidos = 0, bloqueado = false WHERE id = $3`,
      [hash, passwordExpira, usuarioId]
    );

    await registrarAuditoria(usuarioId, 'PASSWORD_CAMBIADO', 'Password actualizado con token', req.ip, true);
    res.json({ mensaje: 'Password actualizado exitosamente' });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============================================================
// CONSULTAR CEDULA EN EL TSE — GET /auth/consultar-cedula/:cedula
// Consulta el TSE (institucion externa) para autocompletar
// nombre y apellidos en el registro. Llamada API a API.
// ============================================================
router.get('/consultar-cedula/:cedula', async (req, res) => {
  try {
    const { cedula } = req.params;

    // LLAMADA API A API: tu Node -> TSE (puerto 5001)
    const respuesta = await axios.get(`${TSE_URL}/personas/${cedula}`);

    // El TSE encontro la persona: devolvemos sus datos a Flutter
    res.json(respuesta.data);
  } catch (error) {
    // Si el TSE respondio 404 (cedula no registrada)
    if (error.response && error.response.status === 404) {
      return res.status(404).json({
        encontrado: false,
        mensaje: 'Cedula no registrada en el TSE',
      });
    }
    // Si el TSE esta caido o fallo
    res.status(500).json({ error: 'No se pudo consultar el TSE' });
  }
});

module.exports = router;