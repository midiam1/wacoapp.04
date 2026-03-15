
# Blueprint: Integración de Acceso con WordPress

## Visión General

El objetivo es añadir una funcionalidad de inicio de sesión en la página de usuario de la aplicación, permitiendo a los usuarios autenticarse contra un sitio de WordPress.

## Diseño y Estilo

- **Formulario Moderno:** Se diseñará un formulario limpio y minimalista, siguiendo las guías de Material Design 3.
- **Campos Claros:** Los campos de texto para usuario y contraseña tendrán íconos y etiquetas claras.
- **Visibilidad de Contraseña:** Se añadirá un ícono de "ojo" en el campo de contraseña para que el usuario pueda mostrarla u ocultarla al escribir.
- **Botón con Énfasis:** El botón de "Acceder" tendrá un estilo destacado para ser el principal llamado a la acción.
- **Feedback Visual:** Se añadirán indicadores de carga mientras se realiza la autenticación y mensajes de error o éxito visualmente claros.

## Plan de Implementación

1.  **Crear `blueprint.md`:** Documentar el plan (¡Este mismo archivo!).
2.  **Analizar Estructura:** Identificar el archivo de la página de usuario en el proyecto `wacoapp.04`.
3.  **Añadir `http`:** Incluir el paquete `http` para la comunicación con la API de WordPress.
4.  **Construir Formulario (UI):**
    - Crear un nuevo widget `LoginForm` que contenga los `TextField` para usuario/contraseña y el botón.
    - Integrar este widget en la página de usuario.
5.  **Lógica de Autenticación (Backend):**
    - Crear una clase `AuthService` que encapsule la lógica de la petición a WordPress.
    - El método `login(username, password)` enviará las credenciales y gestionará la respuesta.
    - Se utilizará la API REST de WordPress. La opción más segura es a través de un plugin como "JWT Authentication for WP REST API".
6.  **Gestión de Estado:**
    - Se usará un `ChangeNotifier` (del paquete `provider`) para gestionar el estado de autenticación del usuario (conectado/desconectado).
    - El token recibido se almacenará de forma segura.
    - La UI de la página de usuario cambiará dinámicamente: mostrará el formulario si no está conectado, o la información del perfil si lo está.
