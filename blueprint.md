
# Blueprint de la App: "Waco" v0.4

## Visión General

"Waco" es una aplicación cliente para un sitio de WordPress. Su propósito es ofrecer una experiencia móvil nativa para el contenido y las funcionalidades del sitio. Incorpora un sistema de autenticación de usuarios y un **menú de navegación interno con control de acceso basado en los roles de WordPress**, permitiendo una experiencia personalizada para cada tipo de usuario.

## Diseño y Estilo

*   **Tema Principal:** La aplicación utiliza un tema oscuro (`dark theme`) con `Material Design 3`. El fondo principal es una imagen artística (`roraima_van_gogh.jpg`) que establece una identidad visual única.
*   **Layout General:** La estructura se basa en un `Scaffold` con un `body` que se extiende detrás de la `AppBar` y la `BottomNavigationBar`, logrando un efecto de transparencia y profundidad.
*   **AppBar (Barra Superior):**
    *   Transparente con un efecto de desenfoque (`BackdropFilter`) para una integración suave con el fondo.
    *   **Logo:** Muestra el logo de la app, que también funciona como un botón para abrir un diálogo "Acerca de".
    *   **Reloj y Fecha:** Un widget en tiempo real que muestra la hora y la fecha actual.
    *   **Icono de Menú (☰):** Es condicional. Solo aparece si el usuario ha iniciado sesión.
*   **BottomNavigationBar (Barra Inferior):**
    *   Transparente con efecto de desenfoque. Contiene la navegación principal: "Inicio", "Literatura" y "Usuario".
    *   Los iconos tienen un color ámbar para el elemento seleccionado y blanco para los no seleccionados.
*   **Paneles de Contenido (`InfoCard`):**
    *   **Efecto Glassmorphism:** Las tarjetas de contenido (como la de la página de inicio que ahora muestra **"Miranda"**) usan un `BackdropFilter` para crear un efecto de "vidrio esmerilado", unificando el estilo con la `AppBar` y la barra de navegación.
    *   Tienen un fondo negro semitransparente, bordes redondeados y un borde sutil para destacar sobre la imagen principal.
*   **Experiencia de Usuario (UX):**
    *   **Carga de Login:** Durante el inicio de sesión, la pantalla se cubre con una capa de desenfoque y un indicador de progreso, proporcionando un feedback visual claro y elegante.
    *   **Drawer (Menú Lateral):** El panel de menú tiene un fondo negro semitransparente.
    *   **Perfil de Usuario:** En la página de perfil, ahora se muestran los **roles del usuario** (ej. "Administrator", "Editor") debajo de su nombre.

## Arquitectura y Características

### 1. Autenticación y Roles de Usuario (WordPress)

*   **Servicio de Autenticación (`AuthService`):**
    *   Se comunica con el plugin **JWT Authentication for WP REST API**.
    *   `login()`: Envía las credenciales para obtener un token de autenticación.
    *   `getProfile()`: Usa el token para obtener los datos del usuario del endpoint `/wp/v2/users/me?context=edit`. El `context=edit` es crucial, ya que permite **recuperar los roles del usuario**.
*   **Gestión de Estado (`AuthProvider`):**
    *   Utiliza `ChangeNotifier` y `Provider` para gestionar el estado de autenticación (`isAuthenticated`, `user`, `token`) a nivel global.
*   **Páginas de Usuario:**
    *   `LoginPage`: Formulario con validación, visibilidad de contraseña y gestión de estados de carga/error.
    *   `ProfilePage`: Muestra avatar, nombre, **roles del usuario** y un botón de "Cerrar Sesión".

### 2. Navegación Secundaria y Control de Acceso (Menú Estático)

*   **Menú Definido en la App (`MainDrawer`):**
    *   Se ha **eliminado la dependencia del API de menús de WordPress**. El menú ya no se carga dinámicamente desde el servidor.
    *   La estructura del menú está **definida estáticamente** dentro del código del widget `MainDrawer`.
*   **Control de Acceso Basado en Roles (RBAC):**
    *   El `MainDrawer` accede al `UserModel` actual a través del `AuthProvider`.
    *   Utiliza la lista de `roles` del usuario para **mostrar u ocultar condicionalmente** los elementos del menú usando sentencias `if (user.hasRole('rol_especifico'))`.
    *   Esto permite un control de acceso preciso y seguro, gestionado directamente desde el código de la app.
*   **Contenido del Menú Actual:**
    *   **"Formulario Base Electoral 2026":** Visible para todos los usuarios autenticados. Abre una `ContentPage` que carga una URL externa.
    *   **Secciones por Roles (Ejemplos):** Se han añadido placeholders para secciones visibles solo para `transcriptor`, `editor` o `administrator`.

### 3. Modelos de Datos

*   **`UserModel`:** Estructura los datos del usuario: ID, nombre, URL del avatar y, más importante, una **lista de `roles`**. Incluye un método `hasRole(String role)` para facilitar las comprobaciones.
*   **`MenuItem`:** Este modelo de datos **ha sido eliminado** en favor del menú estático.

