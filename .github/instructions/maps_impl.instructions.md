---
applyTo: '**'
---
PREGUNTAR ALGO EN CADA CONSULTA REFERENTE AL MAPA
ACTUALMENTE ESTAMOS ASIENDO CON ASYNC AWAIT , CONSULTAR Y OFRECER SOLUCIONES ESCALABLES, OPTIMOS Y CODIGO LIMPIO

REQUERIMIENTO TÉCNICO: GOOGLE MAPS EN TIEMPO REAL
App Asistencia Motorizados - Módulo GPS y Mapas
Fecha: 15 de Octubre 2025
Versión: 2.0 FINAL
Proyecto: Motify - Trazabilidad de Motorizados
Estrategia: Google Maps Optimizado
Presupuesto: $140/mes de $200 crédito gratuito (70% utilizado)

📌 1. OBJETIVO
Implementar sistema de mapas profesional con Google Maps para tracking de motorizados en tiempo real con 4 vistas distintas:

Admin Dashboard Map: Vista de equipo completo con todos los motorizados
Motorizado Detail Map: Vista individual de seguimiento de un motorizado
Motorizado Route Map: Vista de ruta activa en la app del motorizado
Admin Anfitriona Geocercas: Gestión de zonas geográficas de validación
🎯 2. ALCANCE
2.1 Funcionalidades Frontend (Flutter)
✅ Captura de GPS cada 30 segundos en background (motorizado)
✅ Envío automático de ubicación al backend
✅ Mapa interactivo Google Maps con marcadores personalizados
✅ Mapa individual de motorizado con historial de ruta
✅ Mapa de ruta activa con polylines de recojo a entrega
✅ Autocompletar direcciones con Places API
✅ Geocercas con círculos personalizados
✅ Navegación integrada con Google Maps nativa
✅ Manejo de permisos de ubicación (Android/iOS)
✅ Modo offline: cache de última ubicación conocida
2.2 Funcionalidades Backend (FastAPI)
✅ Endpoint para recibir actualizaciones de ubicación
✅ Endpoint para consultar ubicación de un motorizado
✅ Endpoint para consultar ubicaciones de un grupo
✅ Endpoint para calcular rutas optimizadas (Directions API)
✅ Endpoint para calcular distancias y ETAs (Distance Matrix)
✅ Almacenamiento en base de datos con historial
✅ Cache de última ubicación (Redis)
✅ Validación de coordenadas y timestamps

🏗️ 3. ARQUITECTURA PROPUESTA
┌─────────────────┐
│ MOTORIZADO APP  │
│  (Background    │
│   Service)      │
└────────┬────────┘
         │ GPS cada 30s (solo en_ruta)
         │ GPS cada 5min (jornada_activa)
         │ POST /location/update
         ▼
┌─────────────────────────────────────────┐
│   BACKEND (FastAPI)                     │
│  ┌──────────────────────────────────┐   │
│  │  Location API                    │   │
│  │  /update                         │   │
│  │  /user/{id}                      │   │
│  │  /group/{id}                     │   │
│  │  /directions (Google API)        │   │
│  │  /distance-matrix (Google API)   │   │
│  └─────────┬────────────────────────┘   │
│            │                             │
│  ┌─────────▼─────────┐                  │
│  │   PostgreSQL DB   │                  │
│  │  user_locations   │                  │
│  └───────────────────┘                  │
│            │                             │
│  ┌─────────▼─────────┐                  │
│  │  Redis Cache      │                  │
│  │  last_location    │                  │
│  └───────────────────┘                  │
└────────┬────────────────────────────────┘
         │ GET /location/group/{id}
         │ polling cada 60s (optimizado)
         ▼
┌─────────────────┐
│   ADMIN APP     │
│  - Dashboard    │
│  - Detail Page  │
│  - Google Maps  │
└─────────────────┘


📦 4. TECNOLOGÍAS Y DEPENDENCIAS
dependencies:
  flutter:
    sdk: flutter
  
  # Estado (ya instalado)
  flutter_riverpod: ^2.5.3
  
  # GPS y Permisos (ya instalados)
  geolocator: ^10.0.0
  permission_handler: ^11.0.1
  
  # ⭐ MAPAS - GOOGLE MAPS
  google_maps_flutter: ^2.5.0
  google_maps_flutter_web: ^0.5.4+2
  
  # Places API (autocompletar)
  google_places_flutter: ^2.0.9
  
  # Navegación externa
  url_launcher: ^6.2.2
  
  # HTTP (ya instalado)
  http: ^1.2.0
  
  # Background tasks
  workmanager: ^0.5.2
  
  # Cache local
  shared_preferences: ^2.2.2
  sqflite: ^2.3.0
  
  # WebSockets (ya instalado)
  web_socket_channel: ^2.4.0

4.2 requeriments>
# Ya instalados
fastapi==0.104.1
uvicorn==0.24.0
sqlalchemy==2.0.23
asyncpg==0.29.0
pydantic==2.5.0

# NUEVOS - Redis y Mapas
redis==5.0.1
aioredis==2.0.1
geopy==2.4.1

# Google Maps APIs
googlemaps==4.10.0

# Para reportes PDF con mapas estáticos
requests==2.31.0
Pillow==10.1.0

5. ESTRUCTURA
lib/
├── core/
│   ├── models/
│   │   ├── user_location.dart          # NUEVO - Modelo de ubicación
│   │   ├── route_point.dart            # NUEVO - Punto de ruta
│   │   └── place_suggestion.dart       # NUEVO - Sugerencias Places
│   │
│   ├── services/
│   │   ├── location_service.dart       # NUEVO - Servicio GPS
│   │   ├── google_maps_service.dart    # NUEVO - Servicio Google Maps
│   │   ├── places_service.dart         # NUEVO - Places API
│   │   └── api_service.dart            # MODIFICAR - Agregar endpoints
│   │
│   ├── providers/
│   │   ├── location_provider.dart      # NUEVO - Provider de ubicaciones
│   │   ├── map_provider.dart           # NUEVO - Provider de mapas
│   │   └── places_provider.dart        # NUEVO - Provider de Places
│   │
│   └── constants/
│       └── google_maps_config.dart     # NUEVO - API Keys y config
│
├── features/
│   ├── admin_motorized/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── admin_dashboard_screen.dart   # MODIFICAR
│   │       │   └── motorized_detail_page.dart    # MODIFICAR
│   │       │
│   │       └── widgets/
│   │           ├── map_placeholder.dart          # ELIMINAR
│   │           ├── google_team_map_view.dart     # NUEVO
│   │           ├── google_detail_map.dart        # NUEVO
│   │           └── custom_map_markers.dart       # NUEVO
│   │
│   ├── admin_hostess/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── geocercas_screen.dart         # NUEVO
│   │       │
│   │       └── widgets/
│   │           └── geocerca_map_editor.dart      # NUEVO
│   │
│   └── motorizado/
│       └── presentation/
│           ├── screens/
│           │   ├── motorizado_dashboard_screen.dart  # MODIFICAR
│           │   └── ruta_screen.dart                  # NUEVO
│           │
│           └── widgets/
│               ├── route_map_widget.dart             # NUEVO
│               └── address_search_widget.dart        # NUEVO - Places
│
└── shared/
    └── widgets/
        ├── google_map_wrapper.dart           # NUEVO - Wrapper base
        ├── custom_marker_builder.dart        # NUEVO - Marcadores custom
        └── map_controls.dart                 # NUEVO - Controles del mapa

5.2 backend fast api
motify_back/
motify_back/
├── app/
│   ├── api/
│   │   └── v1/
│   │       ├── endpoints/
│   │       │   ├── location.py              # NUEVO - Endpoints ubicación
│   │       │   ├── directions.py            # NUEVO - Google Directions
│   │       │   └── geocercas.py             # NUEVO - Gestión geocercas
│   │       │
│   │       └── api.py                       # MODIFICAR - Incluir routers
│   │
│   ├── crud/
│   │   ├── crud_location.py                 # NUEVO - CRUD ubicaciones
│   │   └── crud_geocerca.py                 # NUEVO - CRUD geocercas
│   │
│   ├── db/
│   │   ├── models/
│   │   │   ├── user_location.py             # NUEVO - Modelo ubicación
│   │   │   └── geocerca.py                  # NUEVO - Modelo geocerca
│   │   │
│   │   └── base.py                          # MODIFICAR - Importar modelos
│   │
│   ├── schemas/
│   │   ├── location.py                      # NUEVO - Schemas ubicación
│   │   ├── directions.py                    # NUEVO - Schemas rutas
│   │   └── geocerca.py                      # NUEVO - Schemas geocercas
│   │
│   ├── services/
│   │   ├── google_maps_service.py           # NUEVO - Cliente Google Maps
│   │   └── cache_service.py                 # NUEVO - Redis cache
│   │
│   └── core/
│       ├── config.py                        # MODIFICAR - Config Google/Redis
│       └── redis.py                         # NUEVO - Cliente Redis
│
└── alembic/
    └── versions/
        ├── xxxx_add_user_locations.py       # NUEVA MIGRACIÓN
        └── xxxx_add_geocercas.py            # NUEVA MIGRACIÓN

6. modelo de datos 
CREATE TABLE user_locations (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES usuarios(id_usuario),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy FLOAT,
    timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    work_state VARCHAR(50),  -- 'inactivo', 'jornada_activa', 'en_ruta'
    pedido_id INTEGER REFERENCES pedidos(id_pedido),
    speed FLOAT,
    heading FLOAT,
    route_points JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_user_locations_user_id ON user_locations(user_id);
CREATE INDEX idx_user_locations_timestamp ON user_locations(timestamp DESC);
CREATE INDEX idx_user_locations_user_timestamp ON user_locations(user_id, timestamp DESC);
CREATE INDEX idx_user_locations_work_state ON user_locations(work_state);

CREATE TABLE geocercas (
    id SERIAL PRIMARY KEY,
    admin_anfitriona_id INTEGER NOT NULL REFERENCES usuarios(id_usuario),
    nombre_lugar VARCHAR(255) NOT NULL,
    gps_lat_centro DOUBLE PRECISION NOT NULL,
    gps_lng_centro DOUBLE PRECISION NOT NULL,
    radio_metros INTEGER NOT NULL,
    color VARCHAR(7) DEFAULT '#4285F4',
    activa BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_geocercas_admin ON geocercas(admin_anfitriona_id);
CREATE INDEX idx_geocercas_activa ON geocercas(activa);

7. PRESUUESTO OSTOS 
┌────────────────────────────────────────────────────────────┐
│  API / SERVICIO                    │  COSTO/MES  │  % USO  │
├────────────────────────────────────────────────────────────┤
│  🗺️  Dynamic Maps                   │   $45       │   32%   │
│     - Admin Dashboard (60s refresh)│             │         │
│     - Detail Pages (45s refresh)   │             │         │
│     - Motorizado App               │             │         │
├────────────────────────────────────────────────────────────┤
│  📍 Places API                      │   $40       │   29%   │
│     - Autocompletar direcciones    │             │         │
│     - Búsqueda de lugares          │             │         │
│     - Validación de direcciones    │             │         │
├────────────────────────────────────────────────────────────┤
│  🛰️  Static Maps                    │   $15       │   11%   │
│     - Reportes PDF                 │             │         │
│     - Thumbnails                   │             │         │
│     - Cache inicial                │             │         │
├────────────────────────────────────────────────────────────┤
│  🛣️  Directions API                 │   $10       │    7%   │
│     - Rutas optimizadas            │             │         │
│     - 50 pedidos/día               │             │         │
├────────────────────────────────────────────────────────────┤
│  📊 Distance Matrix API             │   $10       │    7%   │
│     - ETAs en tiempo real          │             │         │
│     - Distancias precisas          │             │         │
├────────────────────────────────────────────────────────────┤
│  🎨 Map Styling                     │   $10       │    7%   │
│     - Tema personalizado           │             │         │
│     - Colores corporativos         │             │         │
├────────────────────────────────────────────────────────────┤
│  🌍 Geocoding API                   │    $5       │    4%   │
│     - Dirección → Coordenadas      │             │         │
│     - Coordenadas → Dirección      │             │         │
├────────────────────────────────────────────────────────────┤
│  🕐 Time Zone API                   │    $5       │    4%   │
│     - Zonas horarias correctas     │             │         │
├────────────────────────────────────────────────────────────┤
│  TOTAL USADO                        │  $140       │  100%   │
│  CRÉDITO MENSUAL GRATUITO          │  $200       │         │
│  MARGEN DE SEGURIDAD                │   $60       │   30%   │
└────────────────────────────────────────────────────────────┘

DYNAMIC MAPS (refresh optimizado):
──────────────────────────────────────────────────
Admin Dashboard (60s refresh):
- (8h × 3600s) / 60s = 480 requests/día
- 480 × 26 días = 12,480 requests/mes
- Dentro de límite gratuito (28,000) ✅

Motorizado Detail (45s refresh):
- Promedio 20 vistas/día × (5min × 60s) / 45s = 27 requests/día
- 27 × 26 = 702 requests/mes
- Dentro de límite gratuito ✅

Motorizado App (rutas):
- 5 motorizados × 6 pedidos = 30 cargas/día
- Static Map inicial + Dynamic al interactuar
- 30 × 26 = 780 Static Maps/mes
- 780 × $2/1000 = $1.56
- Dynamic refresh limitado: 3,900 requests/mes
- Dentro de límite gratuito ✅

TOTAL Dynamic Maps: ~$15/mes
(Con optimizaciones adicionales: $45/mes)

PLACES API:
──────────────────────────────────────────────────
Autocompletar direcciones:
- 30 pedidos/día × 5 búsquedas promedio = 150/día
- 150 × 26 = 3,900 requests/mes
- 3,900 × $17/1000 = $66.30
(Optimizado con cache y debounce: $40/mes)

DIRECTIONS API:
──────────────────────────────────────────────────
Calcular rutas:
- 50 pedidos/día (incrementado) × 26 días = 1,300/mes
- 1,300 × $5/1000 = $6.50
(Redondeado con overhead: $10/mes)

DISTANCE MATRIX API:
──────────────────────────────────────────────────
ETAs y distancias:
- 100 consultas/día × 26 = 2,600/mes
- 2,600 × $5/1000 = $13
(Optimizado: $10/mes)

TOTAL OPTIMIZADO: $140/mes ✅


🔄 9. PLAN DE IMPLEMENTACIÓN POR FASES
Día 1-2: Setup Google Cloud
☑️ Crear proyecto en Google Cloud Console
☑️ Habilitar facturación y activar crédito $200
☑️ Activar APIs necesarias:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Directions API
   - Distance Matrix API
   - Geocoding API
   - Maps Static API
   - Time Zone API
☑️ Generar API Keys (Android, iOS, Web)
☑️ Configurar restricciones de API Keys
☑️ Configurar dashboard de monitoreo de costos
☑️ Configurar alertas de presupuesto ($100, $150)

Día 3-5: Backend Base
☑️ Instalar dependencias: redis, googlemaps, geopy
☑️ Configurar Redis en Docker Compose
☑️ Crear migración Alembic: user_locations
☑️ Crear migración Alembic: geocercas
☑️ Crear modelos SQLAlchemy
☑️ Crear schemas Pydantic
☑️ Implementar cliente Google Maps en backend
☑️ Implementar servicio de cache Redis

Día 6-10: Frontend Base
☑️ Instalar google_maps_flutter y dependencias
☑️ Configurar API Keys en Android/iOS
☑️ Configurar permisos de ubicación
☑️ Crear LocationService básico
☑️ Crear GoogleMapsService wrapper
☑️ Crear modelos Dart (UserLocation, RoutePoint)
☑️ Implementar providers base con Riverpod
☑️ Testing de permisos y GPS

FASE 2: APIs Backend y Tracking GPS (Semana 3)
Día 1-3: Endpoints de Ubicación
☑️ POST /api/v1/location/update
   - Recibir ubicación del motorizado
   - Validar coordenadas
   - Guardar en PostgreSQL
   - Actualizar cache Redis
   - Calcular si está en movimiento

☑️ GET /api/v1/location/user/{user_id}
   - Obtener última ubicación
   - Primero desde Redis, luego DB
   - Validar permisos de acceso

☑️ GET /api/v1/location/group/{group_id}
   - Obtener ubicaciones de grupo
   - Solo última de cada motorizado
   - Incluir info de usuario

☑️ GET /api/v1/location/history/{user_id}
   - Historial con filtros de fecha
   - Paginación
   - Validar permisos

☑️ Testing con Postman/curl

Día 4-5: Integración Google APIs
☑️ POST /api/v1/directions/calculate
   - Integrar Google Directions API
   - Calcular ruta óptima multi-paradas
   - Cachear resultados (24h)
   - Retornar polyline encoded

☑️ POST /api/v1/distance-matrix
   - Integrar Distance Matrix API
   - Calcular ETAs en tiempo real
   - Considerar tráfico actual
   - Cachear (5 minutos)

☑️ Implementar rate limiting
☑️ Implementar retry logic
☑️ Testing completo

FASE 3: Mapas Admin Dashboard (Semana 4)
Día 1-2: Vista Base del Mapa
☑️ Crear GoogleTeamMapView widget
☑️ Integrar Google Maps con API Key
☑️ Implementar carga inicial del mapa
☑️ Centrar en ubicación promedio del equipo
☑️ Configurar controles (zoom, tipo de mapa)
☑️ Aplicar estilo personalizado (branding)

Día 3-4: Marcadores y Tracking
☑️ Crear provider groupLocationsProvider
☑️ Polling cada 60s (optimizado)
☑️ Crear marcadores personalizados:
   - Gris: inactivo
   - Naranja: jornada_activa
   - Verde: en_ruta
☑️ Mostrar avatar del motorizado
☑️ Mostrar nombre abreviado
☑️ Flecha de dirección (heading)
☑️ Animación suave al mover marcador

Día 5: Polylines y Detalles
☑️ Dibujar polylines de rutas activas
☑️ Color según estado del pedido
☑️ Modal al tap en marcador:
   - Foto del motorizado
   - Estado actual
   - Última actualización
   - Botón "Ver Detalle"
☑️ Auto-ajustar zoom para ver todo el equipo
☑️ Botón para centrar en un motorizado específico


FASE 4: Mapa Detalle Motorizado (Semana 5)
Día 1-2: Vista Individual
☑️ Crear GoogleDetailMap widget
☑️ Integrar en motorized_detail_page.dart
☑️ Reemplazar map_placeholder.dart
☑️ Crear provider userLocationProvider
☑️ Refresh cada 45s (optimizado)
☑️ Centrar en motorizado
☑️ Marcador con avatar y estado

Día 3: Historial de Ruta
☑️ Toggle "Mostrar historial (24h)"
☑️ Obtener historial desde backend
☑️ Dibujar polyline de ruta recorrida
☑️ Marcadores en puntos clave
☑️ Timeline con horas
☑️ Filtro por rango de fechas

FASE 5: Motorizado App - Rutas y Navegación (Semana 6)
Día 1-2: Pantalla de Ruta
☑️ Crear RutaScreen (nuevo tab)
☑️ Crear RouteMapWidget
☑️ Mostrar paradas (recojo/entrega)
☑️ Marcadores numerados
☑️ Polyline de ruta planificada
☑️ Highlight de próxima parada
☑️ Distancia y tiempo restante

Día 3: Places API - Autocompletar
☑️ Crear AddressSearchWidget
☑️ Integrar Google Places Autocomplete
☑️ Debounce de 500ms (optimizar requests)
☑️ Mostrar sugerencias en lista
☑️ Selección marca en mapa
☑️ Validación de dirección
☑️ Guardar lugares frecuentes (cache)

Día 4-5: Navegación
☑️ Botón "Navegar" en cada parada
☑️ Implementar deeplink a Google Maps:
   url_launcher con google.navigation://
☑️ Fallback a browser si no hay app
☑️ Botón alternativo para Waze
☑️ Tracking de cuando abre navegación
☑️ Confirmar llegada al regresar

FASE 6: Admin Anfitriona - Geocercas (Semana 7)
Día 1-2: Editor de Geocercas
☑️ Crear GeocercasScreen
☑️ Crear GeocercaMapEditor widget
☑️ Mapa interactivo Google Maps
☑️ Tap para crear nueva geocerca
☑️ Dibujar círculo con radio ajustable
☑️ Slider para cambiar radio (50-500m)
☑️ Color picker personalizado
☑️ Nombre del lugar

Día 3: Gestión de Geocercas
☑️ Lista de geocercas creadas
☑️ Editar geocerca existente
☑️ Eliminar geocerca
☑️ Activar/desactivar
☑️ Ver anfitrionas asignadas
☑️ CRUD completo en backend

Día 4: Validación de Asistencias
☑️ Al marcar asistencia:
   - Obtener geocercas activas
   - Calcular distancia (Geolocator)
   - Validar si está dentro
   - Mostrar error si está fuera
☑️ Indicador visual en mapa
☑️ Historial de validaciones

FASE 7: Optimizaciones y Features Premium (Semana 8)
Día 1-2: Clustering
☑️ Implementar clustering para muchos marcadores
☑️ Usar google_maps_cluster_manager
☑️ Configurar niveles de zoom
☑️ Diseño de cluster personalizado
☑️ Número de elementos en cluster
☑️ Expandir al hacer zoom

Día 3: Cache Agresivo
☑️ Cache de tiles en dispositivo
☑️ SharedPreferences para configuración
☑️ SQLite para historial offline
☑️ Sincronización automática
☑️ Indicador de modo offline
☑️ Queue de requests pendientes

Día 4: Reportes PDF con Mapas
☑️ Generar Static Map desde backend
☑️ URL con marcadores y polyline
☑️ Incrustar imagen en PDF
☑️ Métricas debajo del mapa
☑️ Botón "Descargar Reporte"
☑️ Compartir por WhatsApp/Email

Día 5: Distance Matrix y ETAs
☑️ Calcular ETA real al asignar pedido
☑️ Actualizar ETA cada 5 minutos
☑️ Mostrar en dashboard admin
☑️ Notificar al cliente
☑️ Alertas de retraso
☑️ Historial de precisión de ETAs

FASE 8: Pulido y Testing Final (Semana 9)
Día 1-2: Optimización de Batería
☑️ GPS adaptativo según estado:
   - en_ruta: cada 30s
   - jornada_activa: cada 5min
   - inactivo: OFF
☑️ Background service optimizado
☑️ Wake locks inteligentes
☑️ Fusión de ubicaciones
☑️ Testing de consumo

Día 3: UX y Animations
☑️ Animación suave de marcadores
☑️ Transiciones de cámara
☑️ Loading states elegantes
☑️ Error states informativos
☑️ Feedback visual en acciones
☑️ Tooltips y ayudas

RESULTADO:
✅ App profesional y completa


 10. CRITERIOS DE ACEPTACIÓN
Frontend (Flutter)
✅ App solicita permisos de ubicación al iniciar sesión motorizado
✅ GPS se captura cada 30s cuando en_ruta, cada 5min cuando jornada_activa
✅ Admin ve mapa Google Maps con todos los motorizados de su grupo
✅ Marcadores personalizados con avatar, colores según estado
✅ Al tap en marcador, modal con información del motorizado
✅ Mapa se refresca cada 60s en dashboard (optimizado)
✅ Página de detalle muestra mapa individual (refresh 45s)
✅ Motorizado puede buscar direcciones con autocompletar
✅ Motorizado ve mapa de ruta con paradas numeradas
✅ Botón "Navegar" abre Google Maps app nativa
✅ Admin Anfitriona puede crear/editar geocercas
✅ Validación de asistencia dentro de geocerca funciona
✅ App funciona sin internet: guarda ubicaciones localmente y sincroniza
Backend (FastAPI)
✅ Endpoint POST /location/update recibe y guarda ubicación
✅ Redis almacena última ubicación (TTL 5 min)
✅ Endpoint GET /location/group/{id} con última ubicación de cada uno
✅ Validación de permisos: admin solo ve su grupo
✅ Endpoint de historial con filtros funciona correctamente
✅ Integración con Google Directions API calcula rutas optimizadas
✅ Distance Matrix API retorna ETAs precisos
✅ Cache de rutas (24h) reduce requests repetidos
✅ Rate limiting protege contra exceso de requests
✅ Monitoreo de costos en dashboard de Google Cloud
Integración y Costos
✅ Motorizado envía ubicación adaptativa según estado
✅ Admin recibe ubicaciones con < 70s de latencia (refresh 60s)
✅ Polylines de ruta se dibujan correctamente
✅ Sistema no pierde datos si motorizado está offline
✅ Rendimiento: mapa carga en < 3 segundos
✅ Costo mensual < $140 (monitoreado en Google Cloud)
✅ Alertas de presupuesto configuradas ($100, $150)
✅ Autocompletar funciona con debounce (optimizado)
✅ Navegación con deeplink a Google Maps funciona
✅ Reportes PDF incluyen mapa estático


 11. MONITOREO DE COSTOS
Dashboard de Google Cloud
CONFIGURAR ALERTAS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Alerta al 50% del presupuesto ($100)
   → Email al admin técnico
   → Revisar uso de APIs

2. Alerta al 75% del presupuesto ($150)
   → Email urgente
   → Identificar API que consume más
   → Aplicar optimizaciones adicionales

3. Alerta al 90% del presupuesto ($180)
   → Email crítico
   → Revisar si hay leak de requests
   → Considerar aumentar intervalos de refresh

4. Hard Limit en $200
   → Desactivar APIs automáticamente
   → Notificar a todos los admins


🎯 12. RESULTADO ESPERADO

   ✅ App profesional con Google Maps
✅ Tracking en tiempo real optimizado
✅ Navegación integrada con Maps nativa
✅ Autocompletar de direcciones
✅ Geocercas funcionales
✅ Reportes con mapas estáticos
✅ ETAs precisos en tiempo real
✅ Costo controlado: $140/mes
✅ Margen de seguridad: $60/mes (30%)
✅ Escalable hasta 100 pedidos/día sin exceder presupuesto