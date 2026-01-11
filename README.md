# Plataforma IoT para Campus Universitario

Este proyecto es una plataforma IoT integral y multiprotocolo diseñada para la monitorización de un campus universitario. Fue desarrollado como un proyecto final para el curso de Tecnologías Emergentes, demostrando la integración de múltiples tecnologías para crear una solución cohesiva y funcional.

## Stack Tecnológico

| Componente      | Tecnología Principal     | Versión   |
| --------------- | ------------------------ | --------- |
| **Backend**     | Node.js con Express      | 18.x      |
| **Base de Datos** | PostgreSQL               | 15        |
| **Broker MQTT**   | Eclipse Mosquitto        | 2.0       |
| **Frontend Móvil**| Flutter                  | 3.16+     |
| **Orquestación**  | Docker Compose           | 2.x       |
| **Lenguajes**   | JavaScript, Dart, Python | -         |

---

## Estructura del Proyecto

```
proyecto/
├── backend/              # Servicio API REST (Node.js)
├── database/             # Script de inicialización de la BD
├── flutter_app/          # Aplicación móvil (Flutter)
├── mosquitto/            # Configuración del broker MQTT
├── simulators/           # Scripts de simulación de dispositivos
├── .env                  # Archivo de variables de entorno (debe ser creado)
├── docker-compose.yml    # Orquestador de servicios de infraestructura
└── README.md             # Este archivo
```

---

## Guía de Instalación y Ejecución

Sigue estos pasos para configurar y ejecutar todo el entorno de desarrollo.

### 1. Prerrequisitos

Asegúrate de tener instaladas las siguientes herramientas en tu sistema:

- **Docker y Docker Compose:** Para orquestar la base de datos y el broker MQTT.
- **Node.js y npm:** Para ejecutar el servicio de backend (`v18.x` recomendada).
- **Python:** Para los simuladores de dispositivos (`v3.8+` recomendada).
- **Flutter SDK:** Para compilar y ejecutar la aplicación móvil (`v3.16+` recomendada).
- **Git:** Para clonar el repositorio.

### 2. Configuración Inicial

1.  **Clona el repositorio:**
    ```bash
    git clone <URL_DEL_REPOSITORIO>
    cd proyecto
    ```

2.  **Crea el archivo de entorno:**
    Crea un archivo `.env` en la raíz del proyecto. Este archivo es **crucial** para configurar las credenciales de la base de datos.
    ```bash
    # En la raíz del proyecto (proyecto/.env)
    DB_PASSWORD=mysecretpassword
    ```

### 3. Levantar la Infraestructura con Docker

La base de datos PostgreSQL y el broker Mosquitto se gestionan con Docker Compose.

```bash
# Este comando construirá y levantará los contenedores en segundo plano.
docker-compose up -d
```

- **Base de Datos:** Estará disponible en `localhost:5432`.
- **Broker MQTT:** Estará escuchando en `localhost:1883`.

### 4. Iniciar el Backend

El backend es un servicio Node.js que expone una API REST para que la aplicación Flutter interactúe con los datos.

```bash
# Navega a la carpeta del backend
cd backend

# Instala las dependencias
npm install

# Inicia el servidor de desarrollo
npm start
```

El backend se ejecutará en `http://localhost:8080`.

### 5. Ejecutar los Simuladores de Dispositivos

Los simuladores envían datos de telemetría (como temperatura y ocupación) al broker MQTT, imitando el comportamiento de dispositivos IoT reales.

1.  **Instala la librería MQTT de Python:**
    ```bash
    pip install paho-mqtt
    ```

2.  **Ejecuta cada simulador en una terminal separada:**
    ```bash
    # Terminal 1: Simulador de Temperatura
    python simulators/temperature_simulator.py

    # Terminal 2: Simulador de Ocupación
    python simulators/occupancy_simulator.py
    ```

### 6. Ejecutar la Aplicación Flutter

La aplicación móvil te permite visualizar los datos, gestionar dispositivos y recibir alertas.

1.  **Navega a la carpeta de la aplicación:**
    ```bash
    cd flutter_app
    ```

2.  **Obtén las dependencias de Flutter:**
    ```bash
    flutter pub get
    ```

3.  **Ejecuta la aplicación:**
    Asegúrate de tener un emulador en ejecución o un dispositivo físico conectado.
    ```bash
    flutter run
    ```

---

## Documentación Adicional

- **API REST:** La especificación completa se encuentra en `api-specification.md`.
- **Base de Datos:** El esquema y las relaciones están documentados en `database-schema.md`.
- **Protocolo MQTT:** Los tópicos y la estructura de los mensajes se detallan en `mqtt-protocol.md`.
