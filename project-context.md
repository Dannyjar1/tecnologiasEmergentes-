# Contexto del Proyecto - Plataforma IoT Campus

## Información General
- **Proyecto:** Plataforma IoT multiprotocolo para campus universitario
- **Curso:** Tecnologías Emergentes
- **Tipo:** Proyecto de fin de semestre
- **Estado:** Primer avance completado

## Descripción Breve
Sistema de núcleo IoT reutilizable que integra dispositivos simulados mediante HTTP/REST y MQTT, con motor de reglas, alertas y panel de administración móvil en Flutter.

## Stack Tecnológico Confirmado
- **Backend:** Node.js 18.x + Express 4.x
- **Base de Datos:** PostgreSQL 15 (considerar TimescaleDB)
- **Broker MQTT:** Eclipse Mosquitto 2.0
- **Frontend Móvil:** Flutter 3.16
- **Orquestación:** Docker Compose 2.x
- **Lenguajes:** JavaScript (backend), Dart (Flutter), Python (simuladores)

## Arquitectura en Capas
1. **Presentación:** App móvil Flutter
2. **Servicios:** Backend REST + Cliente MQTT
3. **Mensajería:** Broker Mosquitto
4. **Persistencia:** PostgreSQL
5. **Simulación:** Scripts Python/Node

## Objetivos del Sistema
- Integrar dispositivos IoT heterogéneos
- Centralizar telemetría en tiempo real
- Automatizar alertas mediante reglas configurables
- Proveer visualización móvil intuitiva
- Servir como base reutilizable para futuros proyectos

## Usuarios Objetivo
- Personal administrativo universitario
- Estudiantes y docentes (uso didáctico)
- Gestores de infraestructura

## Alcance Funcional Mínimo
1. Gestión de dispositivos (CRUD)
2. Ingesta de telemetría (HTTP + MQTT)
3. Motor de reglas y alertas
4. Panel móvil con gráficas
5. Simuladores de dispositivos
6. Despliegue con Docker

## Progreso Actual (Avance 1)
✅ Backend REST con endpoints básicos funcionales
✅ Integración MQTT con Mosquitto operativa
✅ Prototipo Flutter navegable
✅ Simulador Python publicando datos
⚠️ Pendiente: persistencia, motor de reglas, gráficas

## Repositorio
[Pendiente configurar en GitHub]