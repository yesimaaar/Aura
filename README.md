# ✨ Aura - AI Visual Planning Assistant

<p align="center">
  <img src="assets/icons/aura_logo.png" alt="Aura Logo" width="120"/>
</p>

<p align="center">
  <strong>Tu asistente de IA para planificación visual y organización personal</strong>
</p>

<p align="center">
  <a href="#características">Características</a> •
  <a href="#tecnologías">Tecnologías</a> •
  <a href="#instalación">Instalación</a> •
  <a href="#uso">Uso</a> •
  <a href="#capturas">Capturas</a>
</p>

---

## 📱 Descripción

**Aura** es una aplicación móvil impulsada por inteligencia artificial que te ayuda a organizar tu vida de manera visual e intuitiva. Usando la potencia de Google Gemini AI, Aura puede analizar imágenes, crear planes de organización, sugerir recetas, armar outfits y gestionar tu calendario, tareas y recordatorios.

## ⚡ Características

### 🤖 Chat con IA
- Conversación natural en español con Aura
- Análisis de imágenes en tiempo real
- Respuestas contextuales y personalizadas
- La IA puede crear tareas, recordatorios, eventos y recetas automáticamente

### 📸 Análisis Visual
- **Organización de espacios**: Analiza tu habitación, oficina o cualquier espacio y recibe un plan de organización
- **Recetas inteligentes**: Toma foto de tu nevera y obtén recetas con los ingredientes disponibles
- **Outfits**: Fotografía tu ropa y recibe sugerencias de combinaciones
- **Vista en vivo**: Análisis en tiempo real con la cámara

### 📅 Sistema de Organización
- **Calendario**: Vista mensual con eventos y tareas
- **Tareas**: Lista de pendientes con prioridades y fechas límite
- **Recordatorios**: Alertas programadas con repetición
- **Recetas**: Biblioteca personal de recetas con ingredientes y pasos

### 🎨 Editor de Imágenes
- Ajustes de brillo, contraste y saturación
- Filtros predefinidos
- Mejora automática con IA

### 🌙 Temas
- Modo oscuro y claro
- Diseño minimalista y elegante

## 🛠️ Tecnologías

### Framework & Lenguaje
| Tecnología | Versión | Descripción |
|------------|---------|-------------|
| ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white) | 3.10+ | Framework de desarrollo multiplataforma |
| ![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white) | 3.10+ | Lenguaje de programación |

### Inteligencia Artificial
| Tecnología | Descripción |
|------------|-------------|
| ![Google](https://img.shields.io/badge/Google_Gemini-4285F4?style=flat&logo=google&logoColor=white) | Gemini 2.0 Flash - Modelo de IA multimodal |
| `google_generative_ai` | SDK oficial de Google para Dart |

### Gestión de Estado & Arquitectura
| Paquete | Uso |
|---------|-----|
| `provider` | Gestión de estado reactivo |
| `shared_preferences` | Persistencia de datos local |

### UI & Diseño
| Paquete | Uso |
|---------|-----|
| `flutter_animate` | Animaciones fluidas |
| `google_fonts` | Tipografía Inter |
| `cupertino_icons` | Iconografía iOS |

### Cámara & Multimedia
| Paquete | Uso |
|---------|-----|
| `camera` | Acceso a cámara del dispositivo |
| `image_picker` | Selección de imágenes de galería |
| `image` | Procesamiento de imágenes |
| `path_provider` | Gestión de rutas de archivos |

### Permisos & Sistema
| Paquete | Uso |
|---------|-----|
| `permission_handler` | Gestión de permisos del sistema |

## 📦 Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── core/
│   ├── constants/           # Constantes de la app
│   └── theme/               # Temas y colores (AuraTheme)
├── models/
│   ├── analysis_result.dart # Resultados de análisis
│   ├── aura_image.dart      # Modelo de imagen
│   └── organization_models.dart # Tareas, recordatorios, recetas, eventos
├── providers/
│   ├── aura_provider.dart   # Estado principal de la app
│   ├── theme_provider.dart  # Estado del tema
│   └── organization_provider.dart # Estado de organización
├── screens/
│   ├── home_screen.dart     # Pantalla principal con chat
│   ├── camera_screen.dart   # Cámara
│   ├── editor_screen.dart   # Editor de imágenes
│   ├── gallery_screen.dart  # Galería
│   ├── live_view_screen.dart # Vista en vivo con IA
│   ├── organization_screen.dart # Calendario, tareas, etc.
│   └── settings_screen.dart # Configuración
├── services/
│   ├── gemini_service.dart  # Integración con Gemini AI
│   ├── camera_service.dart  # Servicios de cámara
│   ├── storage_service.dart # Almacenamiento
│   ├── organization_service.dart # Persistencia de organización
│   └── ...
└── widgets/
    ├── aura_gradient_text.dart # Texto con gradiente
    ├── feature_card.dart    # Tarjetas de características
    └── ...
```

## 🚀 Instalación

### Prerrequisitos
- Flutter SDK 3.10+
- Dart SDK 3.10+
- Android Studio / VS Code
- API Key de Google Gemini

### Pasos

1. **Clonar el repositorio**
```bash
git clone https://github.com/yesimaaar/Aura.git
cd Aura
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Configurar API Key de Gemini**

Obtén tu API key en [Google AI Studio](https://makersuite.google.com/app/apikey)

4. **Ejecutar la aplicación**
```bash
flutter run --dart-define=GEMINI_API_KEY=tu_api_key_aqui
```

## 📖 Uso

### Chat con Aura
Escribe o habla con Aura para:
- Pedirle que analice una imagen
- Crear tareas: *"Créame una tarea para estudiar mañana"*
- Agregar recordatorios: *"Recuérdame llamar al doctor a las 3pm"*
- Guardar recetas: *"Guarda esta receta de pasta carbonara"*
- Agendar eventos: *"Agrega reunión el viernes de 10am a 12pm"*

### Análisis de Imágenes
1. Toca el ícono de cámara o galería
2. Selecciona o toma una foto
3. Aura analizará la imagen y dará sugerencias

### Organización
Accede al botón 📋 en el header para ver:
- 📅 Calendario con eventos
- ✅ Lista de tareas
- 🔔 Recordatorios
- 🍽️ Recetas guardadas

## 🎨 Capturas de Pantalla

| Chat | Organización | Editor |
|------|--------------|--------|
| Chat con IA | Calendario y tareas | Editor de fotos |

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## 👨‍💻 Autor

**Yesimar**
- GitHub: [@yesimaaar](https://github.com/yesimaaar)

---

<p align="center">
  Hecho con ❤️ y Flutter
</p>
