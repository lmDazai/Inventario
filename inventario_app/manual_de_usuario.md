# Manual de Usuario - App de Inventario

## 1. Introducción
Esta aplicación permite gestionar el inventario de equipos tecnológicos de manera eficiente. Permite escanear códigos de barras, capturar la ubicación GPS, tomar fotos y guardar la información en la nube en tiempo real.

## 2. Tecnologías Utilizadas
La aplicación ha sido desarrollada utilizando tecnologías modernas para asegurar rapidez y compatibilidad:

*   **Flutter**: Framework de Google para crear aplicaciones móviles nativas (Android/iOS) con un solo código base.
*   **Dart**: Lenguaje de programación utilizado por Flutter.
*   **Supabase**: Plataforma de backend en la nube (alternativa a Firebase) que gestiona:
    *   **Base de Datos**: Para guardar la información de los ítems.
    *   **Storage**: Para almacenar las fotos de los equipos.
*   **Librerías Clave**:
    *   `mobile_scanner`: Para leer códigos de barras y QR usando la cámara.
    *   `geolocator` y `geocoding`: Para obtener las coordenadas GPS y convertirlas a una dirección física.
    *   `image_picker`: Para tomar fotos con la cámara.

## 3. Requisitos
*   Dispositivo Android con cámara y GPS.
*   Conexión a Internet (WiFi o Datos) para guardar y ver los datos en la nube.
*   Permisos habilitados para: Cámara (fotos y escáner) y Ubicación (GPS).
*   **Modo Oscuro**: La aplicación se adapta automáticamente al tema de tu dispositivo (Claro/Oscuro).

## 4. Guía de Uso

### Pantalla Principal (Listado)
Al abrir la aplicación, verás la lista de todos los ítems registrados, ordenados por fecha (los más recientes primero).
*   Cada tarjeta muestra la foto, el tipo de equipo, el ID y la ubicación.
*   **Actualizar lista**: La lista se actualiza automáticamente si alguien más agrega un ítem.
*   **Buscar Ítem**: Usa el ícono de **Lupa** en la barra superior para buscar un equipo.
    *   **Escanear**: Escanea el código de barras/QR para encontrar el equipo rápidamente.
    *   **Manual**: Ingresa el código manualmente si no puedes escanearlo.

### Agregar Nuevo Ítem
1.  Presiona el botón **"Nuevo Ingreso"** (abajo a la derecha).
2.  **Verificación de Duplicados**: El sistema verificará automáticamente si el código ingresado ya existe. Si es así, te avisará y no permitirá guardar duplicados.
3.  **Escanear Código**:
    *   Toca el ícono de código QR junto al campo "ID".
    *   Apunta la cámara al código de barras del equipo.
    *   Al detectarlo, la pantalla se cerrará y el código aparecerá automáticamente en el campo.
3.  **Completar Datos**:
    *   **Tipo**: Selecciona el tipo de equipo (PC, Pantalla, etc.).
    *   **Subtipo (Solo PC)**: Si eliges PC, selecciona si es Torre o AIO.
    *   **Ubicación**: Toca el ícono de ubicación (pin) para obtener tu dirección actual por GPS.
    *   **Estado**: Selecciona "Operativo" o "Inactivo".
4.  **Tomar Foto**:
    *   Toca el cuadro gris con el ícono de cámara.
    *   Toma la foto del equipo y confírmala.
5.  **Guardar**: Presiona "GUARDAR DATOS". Si todo está bien, volverás a la lista principal.

### Editar o Eliminar
*   **Editar**: Toca cualquier ítem en la lista para abrir el formulario con sus datos cargados. Modifica lo que necesites y dale a Guardar.
*   **Eliminar**: Dentro del formulario de edición, toca el ícono de **basura rojo** en la barra superior. Confirma la acción para borrar el ítem permanentemente.

## 5. Solución de Problemas Comunes
*   **"Permiso denegado"**: Ve a la configuración de tu teléfono -> Aplicaciones -> Inventario App -> Permisos, y asegúrate de permitir Cámara y Ubicación.
*   **No guarda la foto**: Verifica que tengas conexión a internet. Si el problema persiste, contacta al administrador para revisar los permisos de Supabase.
*   **Ubicación incorrecta**: Asegúrate de estar en un lugar con señal GPS (cielo abierto o cerca de ventanas) para mayor precisión.
