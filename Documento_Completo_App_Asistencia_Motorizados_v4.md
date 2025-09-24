Documento Funcional y Técnico – App Asistencia Motorizados
Versión 2.7 (Flujos Detallados) – Flutter (Android/iOS) – Backend local con futura integración Odoo
1. Introducción
App móvil para trazabilidad de motorizados y control de asistencia de anfitrionas y motorizados, con roles diferenciados.

Diseñada para operar con y sin conexión a internet, guardando los datos de evidencia localmente para sincronizarlos automáticamente al recuperar la señal.

Fotos comprimidas se suben a Cloud Storage (Google Cloud, S3, Backblaze B2).

La base de datos solo guarda la URL de la foto y la metadata asociada (usuario, pedido/asistencia, hora, GPS).

2. Roles y Vistas
Motorizado
Login con credenciales entregadas por admin/super admin.

Marca asistencia de entrada y salida con foto obligatoria. La app registra GPS y hora automáticamente para validar el inicio y fin de su jornada laboral.

Ingresa pedidos asignados (puntos de recojo y entrega).

Organiza el orden de los puntos en la app (drag-and-drop).

Visualiza en el mapa la ruta sugerida para el bloque de entrega activo (desde el primer recojo hasta la última entrega).

En cada parada: toma foto obligatoria, la app registra GPS y hora automáticamente.

Consulta historial propio de rutas, pedidos y asistencias realizadas.

Se comunica con su administrador a través de un chat interno en la app.

Admin Motorizado
Login con credenciales entregadas por super admin.

Panel con dashboard dinámico para ver y gestionar su grupo de motorizados. El dashboard incluye métricas en tiempo real como:

Motorizados con jornada activa.

Pedidos completados en el día.

Tiempo promedio por bloque de entrega (desde el primer recojo a la última entrega).

Estado de los motorizados (inactivo, jornada activa, en ruta).

Crear, editar, actualizar y eliminar motorizados de su grupo.

Asigna credenciales y datos al crear usuario motorizado.

Asigna pedidos por WhatsApp (por ahora).

Recibe notificaciones automáticas cuando un motorizado inicia o finaliza su jornada.

Recibe notificaciones de confirmación de cada parada.

Visualiza en tiempo real la ubicación de cada motorizado. Cuando un motorizado tiene un pedido en su poder, se dibuja la ruta activa del bloque de entrega en el mapa.

Consulta las asistencias (entradas/salidas) de su equipo, incluyendo las evidencias.

Consulta rutas realizadas y pendientes; visualiza evidencias (foto, GPS, hora).

Puede solicitar nueva evidencia en caso de reclamo.

Genera reportes PDF con resumen de rutas, tiempos, asistencias y evidencias.

Envía notificaciones push a motorizados.

Se comunica con su equipo a través de un chat interno.

Super Admin
Login con credenciales de super admin.

Dashboard global con métricas consolidadas de todos los motorizados y anfitrionas.

Gestión total de usuarios y roles: crear, editar, actualizar y eliminar admins, motorizados y anfitrionas.

Asigna credenciales y datos a cada usuario creado.

Visualiza todos los motorizados y anfitrionas en el dashboard global y en el mapa.

Consulta todas las rutas, pedidos y asistencias.

Supervisa posiciones en tiempo real.

Envía notificaciones push masivas o individuales.

Descarga reportes avanzados PDF (todas las evidencias y rutas).

Anfitriona
Login con credenciales entregadas por admin/super admin.

Marca asistencia: entrada/salida con foto obligatoria, la app registra GPS y hora automáticamente.

Consulta historial propio de asistencias (fechas, horas, ubicaciones, evidencias).

Se comunica con su administrador a través de un chat interno en la app.

Admin Anfitriona
Login con credenciales entregadas por super admin.

Panel con dashboard dinámico para ver y gestionar su grupo de anfitrionas, con métricas como últimas asistencias registradas y cumplimiento.

Crear, editar, actualizar y eliminar anfitrionas de su grupo.

Asigna credenciales y datos al crear usuario anfitriona.

Define geocercas (radios geográficos) para los puntos de trabajo para validar la ubicación de la asistencia.

Recibe notificaciones automáticas cuando una anfitriona marca asistencia.

Consulta y visualiza evidencias (foto, hora, GPS).

Puede solicitar nueva evidencia en caso de reclamo.

Genera reportes PDF de asistencias y evidencias.

Envía notificaciones push a anfitrionas.

Se comunica con su equipo a través de un chat interno.

3. Flujos Detallados
Motorizado
Login → ve pantalla principal con la opción de "Marcar Entrada". Su estado es 'Inactivo'.

Marca su asistencia de entrada con foto. La app captura la evidencia y la sincroniza. Su estado cambia a 'Jornada Activa'.

Se envía una notificación al admin: "[Motorizado] ha iniciado su jornada."

Tras marcar entrada, accede a la lista de pedidos. Puede organizar el orden de las paradas (drag-and-drop) para planificar su ruta.

Se dirige a su primer punto de recojo.

Llega al primer recojo y lo confirma con una foto. Este es el disparador que inicia el "bloque de entrega".

La app inicia la "Ruta Activa" en el mapa.

El estado del motorizado cambia a 'En Ruta'.

El estado del pedido cambia a 'en_proceso' y comienza a contar el tiempo de entrega.

Se envía una notificación al admin: "[Motorizado] ha recogido el pedido [código]."

Si hay más recogos en el bloque, los confirma de la misma manera, actualizando la ruta consolidada en el mapa.

Realiza las entregas, confirmando cada una con una foto.

Al confirmar la última entrega del bloque, la "Ruta Activa" finaliza.

El estado del motorizado vuelve a 'Jornada Activa' (listo para otro bloque o para finalizar el día).

Consulta historial y se comunica con su admin vía chat si es necesario.

Al finalizar todos los pedidos del día, regresa a la pantalla principal y marca su salida repitiendo el proceso de la foto. Su estado vuelve a 'Inactivo'.

Admin Motorizado
Login → ve dashboard con métricas en tiempo real y mapa de seguimiento de su equipo.

Crea, edita, actualiza o elimina motorizados de su grupo.

Asigna pedidos por los canales definidos (ej. WhatsApp).

Recibe notificaciones de inicio/fin de jornada y de cada parada confirmada.

Usa el chat interno para dar instrucciones o resolver dudas.

Genera reportes PDF y envía notificaciones push según necesidad.

Anfitriona
Login → ve directamente la pantalla de asistencia con los botones de "Entrada" y "Salida".

Marca su asistencia (ej. "Entrada") con una foto obligatoria.

La app valida que el GPS esté dentro de la geocerca definida y captura la hora. Si no hay conexión, la evidencia se guarda localmente para sincronizarla después.

Una vez confirmada, se envía una notificación al admin de anfitrionas.

Puede consultar su historial de asistencias y comunicarse con su admin vía chat si es necesario.

Admin Anfitriona
Login → ve el dashboard de su equipo de anfitrionas con métricas de asistencia.

Crea y gestiona las geocercas para los puntos de trabajo desde un mapa.

Crea, edita, actualiza o elimina anfitrionas de su grupo.

Recibe notificaciones cuando una anfitriona marca su asistencia.

Visualiza las evidencias (foto, ubicación, hora) y se comunica con su equipo vía chat.

Genera reportes PDF de asistencias y envía notificaciones push.

4. Ejemplo de Pantallas
(Se infieren de los flujos y roles)

5. Modelo de Datos
## Usuario
- id_usuario: int
- nombre: string
- apellido: string
- rol: ['motorizado', 'admin_motorizado', 'super_admin', 'anfitriona', 'admin_anfitriona']
- grupo_id: int
- usuario: string
- contraseña: string (hash)
- activo: boolean
- estado: ['inactivo', 'jornada_activa', 'en_ruta'] // Nuevo campo para motorizados

## Pedido
- id_pedido: int
- codigo_pedido: string
- motorizado_id: int
- admin_id: int
- titulo: string
- nombre_remitente: string
- telefono_remitente: string
- descripcion: text (nullable)
- instrucciones: text (nullable)
- estado: ['pendiente', 'en_proceso', 'finalizado', 'cancelado', 'con_incidencia']
- fecha_creacion: datetime
- fecha_asignacion: datetime
- fecha_finalizacion: datetime (nullable)

## Parada
- id_parada: int
- pedido_id: int
- tipo: ['recojo', 'entrega']
- direccion: string
- orden: int
- foto_url: string
- gps_lat: float
- gps_lng: float
- fecha_hora: datetime
- confirmado: boolean
- notas: string (nullable)

## Asistencia
- id_asistencia: int
- usuario_id: int
- tipo: ['entrada', 'salida']
- foto_url: string
- gps_lat: float
- gps_lng: float
- fecha_hora: datetime
- confirmado: boolean

## Geocerca
- id_geocerca: int
- admin_anfitriona_id: int
- nombre_lugar: string
- gps_lat_centro: float
- gps_lng_centro: float
- radio_metros: int

## MensajeChat
- id_mensaje: int
- remitente_id: int
- destinatario_id: int
- mensaje: text
- fecha_hora: datetime
- leido: boolean
