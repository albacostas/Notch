# Notch

App para **macOS** desarrollada en **Swift** que añade utilidades al **notch** (la muesca superior de la pantalla) mostrando accesos rápidos en forma de ventanas integradas.

Actualmente incluye dos ventanas principales:

- **Notas**: para añadir y eliminar tareas rápidas.
- **Spotify Mini Player**: un reproductor compacto para controlar Spotify, con progreso en tiempo real y fondo dinámico basado en la carátula.

---

## Funcionalidades

### 1) Notas / To‑Do
- Crear tareas o notas rápidas.
- Eliminar tareas cuando ya no sean necesarias.

> Pensado para capturar cosas “por hacer” sin salir del flujo de trabajo.

### 2) Spotify Mini Player
- Controles:
  - **Play / Pause**
  - **Siguiente** / **Anterior**
- **Barra de reproducción** que se actualiza mientras se reproduce la canción.
- **Seek**: si arrastras la barra, la reproducción salta al minuto/segundo indicado.
- Visualización de:
  - **Carátula** del tema actual.
- **Fondo dinámico**:
  - El fondo de la ventana se genera a partir de los **colores principales/dominantes** de la carátula mediante un algoritmo de extracción de color.

---

## Requisitos
- macOS 13+
- Xcode
- Swift
- Spotify en ejecución / sesión iniciada

### Spotify API (obligatorio)
Este proyecto requiere credenciales de la **Spotify Web API**:
- `Client ID`
- `Client Secret`

En este repositorio se cargan desde un archivo **`Secrets.plist`**.

#### Formato esperado de `Secrets.plist`
Crea un archivo `Secrets.plist` (por ejemplo en el bundle de la app, según cómo lo tengas implementado) con las claves:
- `SPOTIFY_CLIENT_ID`
- `SPOTIFY_CLIENT_SECRET`

Ejemplo (estructura conceptual):
- `SPOTIFY_CLIENT_ID`: `tu_client_id`
- `SPOTIFY_CLIENT_SECRET`: `tu_client_secret`

---

## Detalles técnicos

- Interfaz enfocada a interacción rápida desde el notch.
- El módulo de Spotify:
  - consulta el estado de reproducción
  - actualiza progreso y carátula
  - calcula colores dominantes de la carátula y los aplica al fondo para integrarlo visualmente con el tema actual
