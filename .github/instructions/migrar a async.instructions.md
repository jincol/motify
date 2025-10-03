---
applyTo: '**'
---

Cambios principales necesarios
Cambiar SQLAlchemy a la versión async (usando async_session, AsyncSession, y métodos async).
Cambiar todas las funciones CRUD a async def y usar await en las operaciones de base de datos.
Adaptar los endpoints y dependencias para usar sesiones async.
Cambiar utilidades de seguridad si alguna depende de sync DB.
Revisar el uso de la sesión en toda la app (no solo en CRUD).
2. Orden recomendado de migración
Paso 1: Migrar la configuración de la base de datos a async

Cambia la creación de la sesión en database.py para usar AsyncSession y async_engine.
Paso 2: Migrar las funciones CRUD

Cambia cada función de def a async def.
Usa await en las queries:
.execute(), .scalars(), .first(), .commit(), .refresh(), etc.
Cambia el tipo de sesión a AsyncSession.
Paso 3: Migrar dependencias y endpoints

Cambia las dependencias que proveen la sesión para que sean async.
Cambia los endpoints que usan estas funciones a async.
Paso 4: Revisar utilidades y middlewares

Asegúrate de que las utilidades de seguridad y middlewares sean compatibles con async.
Paso 5: Probar y ajustar

Haz pruebas exhaustivas para asegurar que todo funciona correctamente.

vamos a migrar 