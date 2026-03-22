
# Blueprint de la App: "Waco" v0.4

## Visión General

"Waco" es una aplicación cliente para un sitio de WordPress. Su propósito es ofrecer una experiencia móvil nativa para el contenido y las funcionalidades del sitio, incluyendo un sistema de autenticación de usuarios y navegación dinámica que refleja la estructura del menú de WordPress.

## Diseño y Estilo

*   **Tema Principal:** La aplicación utiliza un tema oscuro (`dark theme`) con `Material Design 3`. El fondo principal es una imagen artística (`roraima_van_gogh.jpg`) que establece una identidad visual única.
*   **Layout General:** La estructura se basa en un `Scaffold` con un `body` que se extiende detrás de la `AppBar` y la `BottomNavigationBar`, logrando un efecto de transparencia y profundidad.
*   **AppBar (Barra Superior):**
    *   Es transparente para no obstruir la imagen de fondo.
    *   **Logo:** Muestra el logo de la app, que también funciona como un botón para abrir un diálogo "Acerca de".
    *   **Título:** Muestra el título de la aplicación.
    *   **Reloj y Fecha:** Un widget en tiempo real que muestra la hora y la fecha actual.
    *   **Icono de Menú (☰):** Es condicional. Solo aparece en la esquina superior izquierda si el usuario ha iniciado sesión.
*   **BottomNavigationBar (Barra Inferior):**
    *   Es transparente y contiene la navegación principal: "Inicio", "Literatura" y "Usuario".
    *   Los iconos tienen un color ámbar para el elemento seleccionado y blanco para los no seleccionados, asegurando buena visibilidad.
*   **Paneles de Contenido:** La información se presenta en tarjetas con un fondo negro semitransparente, bordes redondeados y una ligera sombra para crear un efecto "lifted" sobre el fondo principal.
*   **Experiencia de Usuario (UX):**
    *   **Carga de Login:** Durante el inicio de sesión, la pantalla se cubre con una capa de desenfoque (`BackdropFilter`) y un indicador de progreso circular, proporcionando un feedback visual claro y elegante.
    *   **Drawer (Menú Lateral):** El panel de menú tiene un fondo negro semitransparente. Mientras carga los datos, muestra un indicador de progreso. Si falla, muestra un mensaje de error útil.

## Arquitectura y Características

### 1. Autenticación de Usuario (WordPress)

*   **Servicio de Autenticación (`AuthService`):**
    *   Se comunica con el plugin **JWT Authentication for WP REST API** de WordPress.
    *   `login()`: Envía las credenciales al endpoint `/jwt-auth/v1/token`.
    *   `getProfile()`: Obtiene los datos del usuario autenticado del endpoint `/wp/v2/users/me`.
*   **Gestión de Estado (`AuthProvider`):**
    *   Utiliza `ChangeNotifier` y `Provider` para gestionar el estado de autenticación (`isAuthenticated`, `user`, `token`) a nivel global.
    *   Notifica a los widgets para que se reconstruyan cuando el estado de autenticación cambia (login/logout).
*   **Páginas de Usuario:**
    *   `LoginPage`: Contiene el formulario con validación de campos, un botón para alternar la visibilidad de la contraseña y gestiona los estados de carga y error.
    *   `ProfilePage`: Se muestra al iniciar sesión. Presenta la foto de perfil (avatar), el nombre del usuario y un botón para "Cerrar Sesión".

### 2. Navegación Dinámica

*   **Navegación Principal:** Gestionada por una `BottomNavigationBar` que permite cambiar entre las tres secciones principales de la aplicación.
*   **Navegación Secundaria (`MainDrawer`):**
    *   Se muestra como un panel lateral que se desliza desde la izquierda.
    *   **Contenido Dinámico:** Los elementos del menú se obtienen en tiempo real desde el sitio de WordPress.
    *   `MenuService`: Se conecta al endpoint del plugin **WP REST API Menus** (`/wp-json/wp-api-menus/v2/menus/42`) para traer la estructura del menú.
    *   `MenuItem` (Modelo): Representa cada elemento del menú, con su título, URL y posibles hijos (para submenús).
    *   **Visibilidad Condicional:** El `Drawer` y su icono de activación (☰) solo están disponibles si `AuthProvider.isAuthenticated` es `true`.

### 3. Modelos de Datos

*   **`UserModel`:** Estructura los datos del usuario (ID, nombre, URL del avatar).
*   **`MenuItem`:** Estructura los datos de los elementos del menú (ID, título, URL, hijos).

