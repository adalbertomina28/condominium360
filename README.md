# Condominium 360° + Comunidad Inteligente

Aplicación multiplataforma para la gestión integral de condominios, desarrollada con Flutter y Supabase.

## Características

### MVP

- **Gestión de unidades y residentes**
  - Registro por apartamento/unidad
  - Roles: residente, administrador, seguridad

- **Módulo de pagos**
  - Registro de mensualidades
  - Historial de pagos
  - Integración futura con Yappy, ACH o tarjetas locales

- **Reservas de áreas comunes**
  - Calendario con disponibilidad en tiempo real
  - Confirmación y cancelación de reservas

- **Tablón de anuncios digital**
  - Noticias, avisos urgentes, circulares
  - Notificaciones push

- **Reportes y solicitudes de mantenimiento**
  - Crear tickets con evidencia (fotos, descripción)
  - Seguimiento del estado (recibido, en proceso, resuelto)

## Estructura del Proyecto

```
lib/
├── config/         # Configuración de la aplicación (temas, rutas, Supabase)
├── controllers/    # Lógica de negocio y manejo de estado
├── models/         # Modelos de datos
├── screens/        # Pantallas de la aplicación
├── services/       # Servicios para interactuar con Supabase
├── utils/          # Utilidades y helpers
├── widgets/        # Widgets reutilizables
└── main.dart       # Punto de entrada de la aplicación
```

## Configuración

1. Crea un proyecto en [Supabase](https://supabase.com/)
2. Actualiza las credenciales en `lib/config/supabase_config.dart`
3. Ejecuta el siguiente comando para instalar las dependencias:

```bash
flutter pub get
```

4. Ejecuta la aplicación:

```bash
flutter run
```

## Tecnologías

- **Frontend**: Flutter (multiplataforma: app móvil + web)
- **Backend**: Supabase (PostgreSQL, autenticación, almacenamiento, funciones edge)

## Próximos Pasos

1. Crear base de datos en Supabase con tablas y relaciones
2. Conectar Flutter con Supabase (usando supabase_flutter)
3. Diseñar UI de cada pantalla (Figma o directamente en Flutter)
4. Probar autenticación y roles
5. Priorizar desarrollo de módulos MVP
