# FROM python:3.12-slim
# # Establece el directorio de trabajo dentro del contenedor
# WORKDIR /app

# # Establece variables de entorno para que Python no genere archivos .pyc y para que los logs se muestren inmediatamente
# ENV PYTHONDONTWRITEBYTECODE 1
# ENV PYTHONUNBUFFERED 1

# # Instala dependencias del sistema si fueran necesarias (ej. build-essential para algunas librerías C)
# # RUN apt-get update && apt-get install -y --no-install-recommends gcc build-essential

# # Copia el archivo de requerimientos
# RUN apt-get update && apt-get install -y gcc libpq-dev
# COPY ./requirements.txt /app/requirements.txt
# RUN pip install --no-cache-dir --upgrade pip
# RUN pip install --no-cache-dir -r /app/requirements.txt

# # Copia todo el contenido del directorio actual (donde está el Dockerfile) al directorio /app del contenedor
# COPY . /app

# # El comando que se ejecutará cuando el contenedor inicie.
# # Uvicorn ejecutará la instancia 'app' del archivo 'main.py' en el directorio 'app'.
# # --host 0.0.0.0 hace que sea accesible desde fuera del contenedor.
# # --port 8000 es el puerto en el que Uvicorn escuchará dentro del contenedor.
# CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
# # --reload es útil para desarrollo, para producción lo quitarías.


#PRODUCCION
FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copiar e instalar dependencias Python
COPY ./requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /app/requirements.txt

# Copiar código
COPY . /app

EXPOSE 8000

# 🚀 Producción: ejecuta migraciones y SIN --reload
CMD alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000