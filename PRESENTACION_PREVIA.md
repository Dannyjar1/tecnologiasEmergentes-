# Documento Técnico de Soporte - Presentación Previa
## Plataforma IoT para Campus Universitario

**Curso:** Tecnologías Emergentes  
**Fecha:** Enero 2026  
**Tipo:** Proyecto Final de Semestre

---

## 1. Resumen Ejecutivo del Proyecto

### 1.1 Contexto

Las instituciones educativas modernas enfrentan el desafío de gestionar infraestructuras cada vez más complejas y distribuidas. El monitoreo manual de condiciones ambientales, ocupación de espacios y estado de equipamiento resulta ineficiente y propenso a errores. Esta problemática se agudiza en campus universitarios con múltiples edificios, laboratorios y áreas comunes que requieren supervisión constante.

### 1.2 Solución Propuesta

Plataforma IoT integral y multiprotocolo diseñada para la monitorización en tiempo real de un campus universitario. El sistema integra dispositivos heterogéneos mediante protocolos HTTP/REST y MQTT, proporcionando:

- **Centralización de datos:** Recopilación unificada de telemetría de múltiples dispositivos
- **Visualización móvil:** Aplicación Flutter intuitiva para monitoreo en cualquier momento y lugar
- **Alertas automatizadas:** Motor de reglas configurable que detecta condiciones anómalas
- **Gestión simplificada:** CRUD completo de dispositivos y configuraciones
- **Simulación realista:** Entorno de pruebas con dispositivos virtuales

### 1.3 Valor Diferencial

| Aspecto | Enfoque Tradicional | Nuestra Solución |
|---------|---------------------|------------------|
| **Integración** | Sistemas aislados por fabricante | Plataforma multiprotocolo unificada |
| **Acceso** | Paneles web de escritorio | App móvil nativa multiplataforma |
| **Escalabilidad** | Licencias costosas por dispositivo | Arquitectura open-source extensible |
| **Implementación** | Semanas de configuración | Despliegue automatizado con Docker |
| **Persistencia** | Bases de datos propietarias | PostgreSQL con potencial TimescaleDB |

**Ventaja competitiva:** Solución académica que sirve como base reutilizable para proyectos de infraestructura inteligente, con enfoque en estándares abiertos y facilidad de extensión.

---

## 2. Arquitectura Tecnológica

### 2.1 Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                     CAPA DE PRESENTACIÓN                     │
│  ┌────────────────────────────────────────────────────────┐ │
│  │         Aplicación Móvil Flutter (Dart 3.0+)           │ │
│  │  • Dashboard de dispositivos  • Gráficas de telemetría │ │
│  │  • Gestión de alertas         • Configuración de reglas│ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ HTTP/REST
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      CAPA DE SERVICIOS                       │
│  ┌────────────────────────────────────────────────────────┐ │
│  │       Backend Node.js 18 + Express 4.x                 │ │
│  │  • API REST (CRUD de dispositivos y telemetría)        │ │
│  │  • Cliente MQTT (suscripción a tópicos)                │ │
│  │  • Motor de reglas y generación de alertas             │ │
│  │  • Lógica de negocio y validaciones                    │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
          ▲                                      │
          │ MQTT Pub/Sub                        │ SQL Queries
          ▼                                      ▼
┌──────────────────────┐          ┌──────────────────────────┐
│  CAPA DE MENSAJERÍA  │          │   CAPA DE PERSISTENCIA   │
│ ┌──────────────────┐ │          │ ┌──────────────────────┐ │
│ │ Eclipse Mosquitto│ │          │ │   PostgreSQL 15      │ │
│ │   Broker MQTT    │ │          │ │                      │ │
│ │   Puerto: 1883   │ │          │ │ • devices            │ │
│ └──────────────────┘ │          │ │ • telemetry          │ │
└──────────────────────┘          │ │ • rules              │ │
          ▲                        │ │ • alerts             │ │
          │ MQTT Publish           │ └──────────────────────┘ │
          │                        └──────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                   CAPA DE DISPOSITIVOS                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  Simulador   │  │  Simulador   │  │  Dispositivos    │  │
│  │ Temperatura  │  │  Ocupación   │  │  Físicos Futuros │  │
│  │  (Python)    │  │  (Python)    │  │   (HTTP/MQTT)    │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Stack Tecnológico Justificado

#### **Backend: Node.js 18 + Express 4.x**
- **Justificación:** Ecosistema maduro para aplicaciones I/O intensivas, ideal para manejar múltiples conexiones MQTT concurrentes
- **Ventajas:** NPM con librerías MQTT probadas (`mqtt.js`), fácil integración con PostgreSQL, curva de aprendizaje accesible
- **Alternativas descartadas:** Python Flask (menor rendimiento en WebSockets), Java Spring (mayor complejidad)

#### **Base de Datos: PostgreSQL 15**
- **Justificación:** RDBMS robusto con soporte JSON para metadata flexible de dispositivos
- **Consideración futura:** Migración a TimescaleDB para optimizar consultas de series temporales
- **Ventajas:** ACID completo, integridad referencial, extensibilidad, comunidad activa
- **Alternativas descartadas:** MongoDB (poca estructura para relaciones), InfluxDB (menor versatilidad para CRUD de dispositivos)

#### **Broker MQTT: Eclipse Mosquitto 2.0**
- **Justificación:** Estándar de facto para IoT ligero, altamente configurable y probado en producción
- **Ventajas:** Bajo consumo de recursos, soporte QoS, autenticación configurable
- **Alternativas descartadas:** RabbitMQ (sobrecargado para este caso), EMQX (innecesariamente complejo)

#### **Frontend Móvil: Flutter 3.16**
- **Justificación:** Única base de código para Android/iOS, rendimiento nativo, widgets Material Design
- **Ventajas:** Hot reload para desarrollo rápido, Provider para gestión de estado, charting libraries maduras
- **Alternativas descartadas:** React Native (menor rendimiento), aplicación web (UX limitada)

#### **Orquestación: Docker Compose 2.x**
- **Justificación:** Simplifica despliegue de infraestructura (DB + Broker), reproducibilidad garantizada
- **Ventajas:** Aislamiento de servicios, configuración declarativa, portabilidad entre entornos
- **Protocolo de comunicación:** HTTP/REST para operaciones CRUD, MQTT para telemetría en tiempo real

### 2.3 Patrones de Diseño Implementados

- **Repository Pattern:** Abstracción de acceso a datos en el backend
- **Provider Pattern:** Gestión de estado reactiva en Flutter
- **Pub/Sub:** Desacoplamiento entre dispositivos y procesamiento de telemetría
- **API Gateway:** Backend como punto único de entrada para el cliente móvil

---

## 3. User Journey y Flujo Funcional de la Demostración

### 3.1 Narrativa del Demo (7-10 minutos)

#### **Fase 1: Contexto y Arranque (1 min)**
> *"Imaginemos que somos el personal técnico del campus. Acabamos de llegar por la mañana y queremos verificar el estado de la infraestructura..."*

1. Mostrar inicio de servicios con Docker Compose
2. Verificar logs del backend iniciando correctamente
3. Demostrar que simuladores están publicando datos a MQTT

#### **Fase 2: Monitoreo en Dashboard (2 min)**
> *"Abrimos nuestra app móvil para obtener una vista general del campus..."*

1. **Pantalla de Dashboard:**
   - Mostrar estadísticas de dispositivos activos/inactivos
   - Visualizar alertas activas (si existen)
   - Navegar por lista de dispositivos registrados

2. **Detalle de Dispositivo:**
   - Seleccionar sensor de temperatura
   - Mostrar ubicación (edificio, piso)
   - Visualizar gráfica de telemetría en tiempo real
   - Explicar valores actuales y tendencias

#### **Fase 3: Gestión de Dispositivos (2 min)**
> *"Necesitamos agregar un nuevo sensor en el laboratorio de química..."*

1. **Crear Nuevo Dispositivo:**
   - Click en botón flotante "+"
   - Completar formulario (nombre, tipo, ubicación, protocolo)
   - Guardar y ver reflejado en lista

2. **Editar Dispositivo Existente:**
   - Cambiar ubicación de un sensor
   - Actualizar estado (mantenimiento/activo)

#### **Fase 4: Sistema de Alertas (2 min)**
> *"La temperatura en el aula A203 excede el umbral seguro..."*

1. **Visualización de Alertas:**
   - Acceder a pantalla de alertas
   - Mostrar alertas críticas/warning/info
   - Explicar campos: dispositivo afectado, valor, threshold

2. **Gestión de Alertas:**
   - Reconocer una alerta (acknowledge)
   - Agregar notas de acción tomada
   - Mostrar historial de alertas cerradas

#### **Fase 5: Telemetría en Tiempo Real (2 min)**
> *"Observemos cómo los datos fluyen continuamente desde los dispositivos..."*

1. **Demostración Live:**
   - Abrir terminal con simulador de temperatura
   - Modificar valor de temperatura en el código del simulador
   - Mostrar actualización en tiempo real en la app
   - Explicar flujo: Simulador → MQTT → Backend → DB → API → App

2. **Gráficas Históricas:**
   - Mostrar gráfica de las últimas 24 horas
   - Filtrar por métrica específica
   - Explicar capacidad de análisis de tendencias

#### **Cierre: Arquitectura y Próximos Pasos (1 min)**
> *"Esta plataforma sienta las bases para un ecosistema IoT completo..."*

- Recapitular flujo de datos completo
- Mencionar componentes dockerizados
- Destacar extensibilidad del sistema

### 3.2 Checklist Pre-Demo

**15 minutos antes:**
- [ ] Levantar Docker Compose (`docker-compose up -d`)
- [ ] Verificar que PostgreSQL esté aceptando conexiones (puerto 5432)
- [ ] Verificar que Mosquitto esté escuchando (puerto 1883)
- [ ] Iniciar backend (`cd backend && npm start`)
- [ ] Verificar respuesta de API en `http://localhost:8080/api/health`
- [ ] Iniciar simuladores en terminales separadas
- [ ] Verificar logs de publicación MQTT
- [ ] Compilar app Flutter en dispositivo/emulador
- [ ] Verificar conectividad app → backend
- [ ] Crear 2-3 dispositivos de prueba si DB está vacía
- [ ] Generar al menos 1 alerta crítica modificando umbral

**Plan B (contingencias):**
- [ ] Tener screenshot de cada pantalla de la app
- [ ] Video de respaldo demostrando telemetría en tiempo real
- [ ] Copia de DB con datos de ejemplo

---

## 4. Análisis de Riesgos con Planes de Contingencia

### 4.1 Riesgos Técnicos

| Riesgo | Probabilidad | Impacto | Plan de Contingencia |
|--------|--------------|---------|----------------------|
| **Backend no inicia por error de BD** | Media | Alto | • Verificar `.env` con credenciales correctas<br>• Recrear contenedor de PostgreSQL<br>• Usar BD SQLite de respaldo con datos pre-cargados |
| **App móvil no conecta con backend** | Media | Crítico | • Verificar IP del backend en `config/constants.dart`<br>• Usar configuración `localhost` para emulador<br>• Demo con capturas de pantalla + explicación verbal |
| **Simuladores no publican a MQTT** | Baja | Medio | • Verificar broker en logs de Mosquitto<br>• Publicar mensajes manualmente con `mosquitto_pub`<br>• Usar datos históricos en DB para gráficas |
| **Gráficas no renderizan correctamente** | Baja | Medio | • Recargar pantalla con pull-to-refresh<br>• Usar versión web de respaldo<br>• Explicar con diagrama estático |
| **Falla de red durante demo** | Baja | Alto | • Configurar todo en red local sin internet<br>• Usar dispositivo físico en lugar de emulador<br>• Tener video pregrabado de 2 minutos |

### 4.2 Riesgos de Presentación

| Riesgo | Probabilidad | Impacto | Plan de Contingencia |
|--------|--------------|---------|----------------------|
| **Exceder tiempo asignado (10 min)** | Media | Medio | • Ensayar con cronómetro 3 veces<br>• Priorizar fases 2, 4 y 5<br>• Omitir fase 3 (CRUD) si es necesario |
| **Proyector no muestra pantalla móvil** | Media | Alto | • Usar scrcpy para espejado en laptop<br>• Capturas de pantalla en presentación PDF<br>• Demo en navegador con versión web |
| **Preguntas técnicas profundas sobre MQTT** | Alta | Bajo | • Preparar diagrama de tópicos y QoS<br>• Explicar con analogía de canales de radio<br>• Remitir a documentación adjunta |
| **Cuestionamiento de escalabilidad** | Alta | Medio | • Mencionar load testing con K6 (planeado)<br>• Explicar estrategia de sharding en PostgreSQL<br>• Citar casos de uso de Mosquitto en producción |

### 4.3 Riesgos de Alcance

| Riesgo | Probabilidad | Impacto | Plan de Contingencia |
|--------|--------------|---------|----------------------|
| **Motor de reglas no completado** | Media | Alto | • Explicar diseño arquitectónico del motor<br>• Demostrar alertas creadas manualmente en DB<br>• Mostrar endpoint API para reglas (aunque no persista) |
| **Autenticación JWT no implementada** | Alta | Bajo | • Reconocer como trabajo futuro<br>• Explicar cómo se integraría (middleware en Express)<br>• No es crítico para POC académico |
| **Rendimiento de gráficas con muchos datos** | Media | Medio | • Limitar queries a últimas 100 mediciones<br>• Implementar paginación en endpoint<br>• Mencionar optimizaciones pendientes (índices, agregaciones) |

---

## 5. Checklist de Preparación Técnica Completa

### 5.1 Infraestructura y Entorno

#### **Repositorio**
- [ ] Código versionado en Git con commits descriptivos
- [ ] `.gitignore` configurado correctamente (excluir `.env`, `node_modules`, etc.)
- [ ] README.md actualizado con instrucciones de instalación
- [ ] Documentación de API en `api-specification.md` completa
- [ ] Esquema de BD en `database-schema.md` con diagrama ER

#### **Docker y Base de Datos**
- [ ] `docker-compose.yml` funcional con PostgreSQL y Mosquitto
- [ ] Variables de entorno en `.env` (no commiteado)
- [ ] Script de inicialización `database/init.sql` crea tablas correctamente
- [ ] Seeds de datos de ejemplo (al menos 5 dispositivos)
- [ ] Backup de BD con datos de demo completo

#### **Backend**
- [ ] `package.json` con todas las dependencias correctas
- [ ] `npm install` ejecuta sin errores
- [ ] Servidor inicia en puerto 8080
- [ ] Endpoints CRUD de dispositivos funcionales (GET, POST, PATCH, DELETE)
- [ ] Endpoint de telemetría con filtros por fecha y dispositivo operativo
- [ ] Cliente MQTT conecta a broker y persiste mensajes en BD
- [ ] Manejo de errores con códigos HTTP correctos (404, 500, etc.)
- [ ] Logs descriptivos con Winston o equivalente

#### **Simuladores**
- [ ] Dependencias Python instaladas (`paho-mqtt`)
- [ ] `temperature_simulator.py` publica cada 5 segundos
- [ ] `occupancy_simulator.py` publica datos realistas (0-100 personas)
- [ ] Tópicos MQTT correctamente configurados (ej: `campus/temp/aula-a203`)
- [ ] Valores generados incluyen metadata JSON válido

### 5.2 Aplicación Móvil Flutter

#### **Configuración**
- [ ] Flutter SDK 3.16+ instalado y en PATH
- [ ] `flutter doctor` sin errores críticos
- [ ] `flutter pub get` descarga dependencias correctamente
- [ ] `config/constants.dart` tiene URL correcta del backend
- [ ] Tema personalizado en `config/theme.dart` aplicado

#### **Modelos y Servicios**
- [ ] Modelo `Device` con serialización JSON funcional
- [ ] Modelo `Telemetry` con formateo de valores y unidades
- [ ] Modelo `Alert` con enums de severidad y estado
- [ ] `ApiService` con métodos para todos los endpoints
- [ ] Manejo de excepciones en llamadas HTTP
- [ ] Timeouts configurados (10 segundos)

#### **Pantallas**
- [ ] `DashboardScreen` muestra estadísticas y dispositivos
- [ ] `DeviceListScreen` con lista filtrable
- [ ] `DeviceDetailScreen` con gráfica de telemetría
- [ ] `AddDeviceScreen` con validación de formulario
- [ ] `AlertsListScreen` con badges de severidad
- [ ] Navegación entre pantallas funcional (Navigator 2.0 o GoRouter)
- [ ] Pull-to-refresh en listas
- [ ] Indicadores de carga (CircularProgressIndicator)
- [ ] Mensajes de error user-friendly

#### **Widgets**
- [ ] `DeviceCard` con estado visual (color según status)
- [ ] `TelemetryChart` renderiza correctamente (fl_chart o charts_flutter)
- [ ] `RealTimeValueCard` muestra último valor recibido
- [ ] Componentes reutilizables en `/widgets`

#### **Testing de App**
- [ ] Compilación en modo debug sin warnings
- [ ] Ejecutar en emulador Android sin crashes
- [ ] Ejecutar en dispositivo físico (opcional pero recomendado)
- [ ] Probar conexión con backend en red local
- [ ] Verificar scroll fluido en listas largas

### 5.3 Documentación y Presentación

#### **Documentos Técnicos**
- [ ] Este documento de soporte completo y revisado
- [ ] Diagrama de arquitectura exportado como imagen
- [ ] Diagrama de flujo de datos (opcional)
- [ ] Capturas de pantalla de cada pantalla de la app
- [ ] Video de 2-3 minutos demostrando flujo completo (backup)

#### **Material de Presentación**
- [ ] Slides con máximo 10 diapositivas
- [ ] Diapositiva de título con nombres del equipo
- [ ] Diapositiva de problema/solución
- [ ] Diapositiva de arquitectura con diagrama
- [ ] Diapositiva de stack tecnológico con justificaciones
- [ ] Diapositiva de demo flow (opcional)
- [ ] Diapositiva de métricas (líneas de código, commits, sprints)
- [ ] Diapositiva de lecciones aprendidas y próximos pasos
- [ ] Transiciones rápidas (no perder tiempo en animaciones)

#### **Ensayo y Timing**
- [ ] Ensayo completo de punta a punta (3 veces mínimo)
- [ ] Cronometrar cada sección (ajustar a máximo 10 min)
- [ ] Practicar respuestas a preguntas frecuentes
- [ ] Validar que todos los miembros conozcan todo el stack
- [ ] Designar quién explica qué parte

### 5.4 Pre-Vuelo (Día de la Presentación)

**2 horas antes:**
- [ ] Clonar repositorio en máquina de presentación
- [ ] Ejecutar `docker-compose up -d` y verificar logs
- [ ] Ejecutar `npm install && npm start` en backend
- [ ] Ejecutar simuladores y verificar publicación MQTT
- [ ] Compilar app y probar en dispositivo/emulador
- [ ] Insertar datos de ejemplo si BD está vacía
- [ ] Verificar conectividad completa end-to-end

**30 minutos antes:**
- [ ] Probar proyector con laptop de respaldo
- [ ] Configurar scrcpy o vysor para espejado móvil
- [ ] Abrir todas las terminales necesarias en tabs separados
- [ ] Cargar slides de presentación
- [ ] Tener video de backup listo para reproducir
- [ ] Silenciar notificaciones en dispositivo móvil y laptop

**Checklist de Contingencia:**
- [ ] Laptop con batería completa + cargador
- [ ] Adaptador HDMI/VGA para proyector
- [ ] Backup de código en USB
- [ ] Hotspot móvil configurado (si red local falla)
- [ ] Contactos de soporte técnico del aula

---

## 6. Métricas del Proyecto

### 6.1 Estadísticas de Desarrollo

| Métrica | Valor Estimado |
|---------|----------------|
| **Líneas de código (Backend)** | ~1,200 líneas |
| **Líneas de código (Flutter)** | ~2,500 líneas |
| **Líneas de código (Simuladores)** | ~200 líneas |
| **Commits en Git** | 50+ commits |
| **Tiempo de desarrollo** | 6-8 semanas |
| **Sprints/Iteraciones** | 3 sprints |
| **Endpoints de API** | 15+ endpoints |
| **Modelos de datos** | 4 modelos principales |
| **Pantallas de UI** | 8-10 pantallas |

### 6.2 Cobertura Funcional

| Funcionalidad | Estado | Prioridad |
|---------------|--------|-----------|
| CRUD de Dispositivos | ✅ Completo | Alta |
| Ingesta de telemetría vía MQTT | ✅ Completo | Alta |
| Visualización en gráficas | ✅ Completo | Alta |
| Sistema de alertas | ⚠️ Parcial | Alta |
| Motor de reglas configurable | ❌ Pendiente | Media |
| Autenticación JWT | ❌ Pendiente | Baja |
| Dashboard administrativo | ✅ Completo | Alta |
| Notificaciones push | ❌ Fuera de alcance | Baja |

---

## 7. Lecciones Aprendidas y Próximos Pasos

### 7.1 Desafíos Técnicos Superados

1. **Integración MQTT con PostgreSQL:** Inicialmente hubo latencia al persistir cada mensaje. Solución: batch inserts cada 5 segundos.
2. **Sincronización de estado en Flutter:** Provider causaba rebuilds innecesarios. Solución: Consumer selectivo en widgets específicos.
3. **Gestión de conexiones MQTT:** El cliente se desconectaba periódicamente. Solución: auto-reconnect con backoff exponencial.

### 7.2 Trabajo Futuro

#### **Corto plazo (siguiente sprint):**
- Completar motor de reglas con UI de configuración
- Implementar autenticación JWT y roles (admin/viewer)
- Optimizar queries de telemetría con índices en timestamp
- Agregar tests unitarios (Jest para backend, widget tests para Flutter)

#### **Mediano plazo (siguiente semestre):**
- Migrar a TimescaleDB para mejor rendimiento en series temporales
- Implementar WebSockets para telemetría push en tiempo real
- Agregar dashboard web con React/Vue
- Desplegar en producción con Kubernetes

#### **Largo plazo (profesional):**
- Soporte para más protocolos (CoAP, LoRaWAN)
- Machine learning para detección de anomalías
- Multi-tenancy para múltiples organizaciones
- Marketplace de drivers de dispositivos

---

## 8. Referencias y Recursos

### 8.1 Documentación Técnica

- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [Flutter Architecture Patterns](https://docs.flutter.dev/development/data-and-backend/state-mgmt/options)
- [MQTT Protocol Specification](https://mqtt.org/mqtt-specification/)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)

### 8.2 Librerías Clave Utilizadas

**Backend:**
- `express` - Framework web
- `pg` - Cliente PostgreSQL
- `mqtt` - Cliente MQTT
- `dotenv` - Gestión de variables de entorno
- `cors` - Manejo de CORS

**Flutter:**
- `http` - Cliente HTTP
- `provider` - Gestión de estado
- `fl_chart` - Gráficas
- `intl` - Formateo de fechas

### 8.3 Herramientas de Desarrollo

- **IDE:** Visual Studio Code con extensiones de Flutter y ESLint
- **API Testing:** Postman/Insomnia
- **MQTT Testing:** MQTT Explorer
- **DB Management:** DBeaver / pgAdmin
- **Control de versiones:** Git + GitHub

---

## 9. Contacto y Repositorio

**Repositorio:** [Pendiente publicar en GitHub]  
**Documentación adicional:**
- `README.md` - Guía de instalación completa
- `api-specification.md` - Especificación de endpoints REST
- `database-schema.md` - Esquema de base de datos
- `mqtt-protocol.md` - Estructura de tópicos y mensajes
- `flutter-app-structure.md` - Arquitectura de la aplicación móvil

---

## 10. Declaración de Autoría

Este proyecto fue desarrollado completamente por el equipo como parte del curso de Tecnologías Emergentes. Todo el código es original, con excepción de las librerías de terceros debidamente citadas. El sistema representa la integración práctica de conceptos aprendidos en:

- Arquitecturas de microservicios
- Protocolos IoT (MQTT, HTTP/REST)
- Desarrollo móvil multiplataforma
- Bases de datos relacionales
- Orquestación de contenedores

**Firma del equipo:** _______________________  
**Fecha:** Enero 2026

---

## Anexo A: Comandos de Ejecución Rápida

```bash
# 1. Levantar infraestructura
docker-compose up -d

# 2. Iniciar backend
cd backend
npm install
npm start

# 3. Iniciar simuladores (terminales separadas)
python simulators/temperature_simulator.py
python simulators/occupancy_simulator.py

# 4. Ejecutar app Flutter
cd flutter_app
flutter pub get
flutter run

# 5. Verificar servicios
curl http://localhost:8080/api/devices
mosquitto_sub -h localhost -t "campus/#" -v

# 6. Detener todo
docker-compose down
```

---

**FIN DEL DOCUMENTO**
