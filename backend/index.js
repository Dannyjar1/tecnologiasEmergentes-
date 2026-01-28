require('dotenv').config();

const express = require('express');
const cors = require('cors');
const mqtt = require('mqtt');
const { Pool } = require('pg');

const app = express();
const port = process.env.PORT || 3000;

// PostgreSQL client - Using direct configuration to avoid dotenv issues
const pool = new Pool({
  user: 'campus_admin',
  host: 'postgres',  // Container name in docker-compose
  database: 'campus_iot',
  password: 'mysecretpassword',
  port: 5432,
});

// MQTT client
const mqttClient = mqtt.connect(process.env.MQTT_BROKER_URL, {
  clientId: 'campus-iot-backend',
  clean: true,
  reconnectPeriod: 1000
});

mqttClient.on('connect', () => {
  console.log('✅ Connected to Mosquitto');
  mqttClient.subscribe('campus/+/+', { qos: 1 }, (err) => {
    if (!err) {
      console.log('📡 Subscribed to campus/+/+');
    }
  });
});

mqttClient.on('message', async (topic, message) => {
  try {
    const parts = topic.split('/');
    const [, deviceId, metric] = parts;
    const payload = JSON.parse(message.toString());

    console.log(`📥 [${deviceId}] ${metric}: ${payload.value}`);

    // Store telemetry in the database
    const query = {
      text: 'INSERT INTO telemetry(device_id, metric, value, unit, timestamp) VALUES($1, $2, $3, $4, $5)',
      values: [deviceId, metric, payload.value, payload.unit, payload.timestamp],
    };
    await pool.query(query);

  } catch (error) {
    console.error('Failed to process MQTT message', error);
  }
});

mqttClient.on('error', (error) => {
  console.error('MQTT Client Error:', error);
});

app.use(cors()); // Enable CORS for all routes
app.use(express.json());

app.get('/', (req, res) => {
  res.send('Campus IoT Backend is running!');
});

// API Endpoints

// Devices
app.post('/api/devices', async (req, res) => {
  try {
    const { deviceId, name, type, location, protocol, metadata } = req.body;
    if (!deviceId || !name || !type) {
      return res.status(400).json({ error: 'Missing required fields: deviceId, name, type' });
    }
    const query = {
      text: 'INSERT INTO devices(device_id, name, type, location, protocol, metadata) VALUES($1, $2, $3, $4, $5, $6) RETURNING *',
      values: [deviceId, name, type, location, protocol, metadata],
    };
    const result = await pool.query(query);
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating device', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

app.get('/api/devices', async (req, res) => {
  try {
    const { status, type, location } = req.query;
    let query = 'SELECT * FROM devices';
    const values = [];
    if (status || type || location) {
      query += ' WHERE ';
      const conditions = [];
      if (status) {
        conditions.push(`status = $${values.length + 1}`);
        values.push(status);
      }
      if (type) {
        conditions.push(`type = $${values.length + 1}`);
        values.push(type);
      }
      if (location) {
        conditions.push(`location = $${values.length + 1}`);
        values.push(location);
      }
      query += conditions.join(' AND ');
    }
    const result = await pool.query(query, values);
    res.json(result.rows);
  } catch (error) {
    console.error('Error getting devices', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

app.get('/api/devices/:deviceId', async (req, res) => {
  try {
    const { deviceId } = req.params;
    const query = {
      text: 'SELECT * FROM devices WHERE device_id = $1',
      values: [deviceId],
    };
    const result = await pool.query(query);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Device not found' });
    }
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error getting device', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

app.patch('/api/devices/:deviceId', async (req, res) => {
  try {
    const { deviceId } = req.params;
    const { name, status, location, building, floor, metadata } = req.body;

    // Dynamically build the update query
    let queryText = 'UPDATE devices SET ';
    const queryValues = [];
    const setClauses = [];

    if (name !== undefined) {
      setClauses.push(`name = $${queryValues.length + 1}`);
      queryValues.push(name);
    }
    if (status !== undefined) {
      setClauses.push(`status = $${queryValues.length + 1}`);
      queryValues.push(status);
    }
    if (location !== undefined) {
      setClauses.push(`location = $${queryValues.length + 1}`);
      queryValues.push(location);
    }
    if (building !== undefined) {
      setClauses.push(`building = $${queryValues.length + 1}`);
      queryValues.push(building);
    }
    if (floor !== undefined) {
      setClauses.push(`floor = $${queryValues.length + 1}`);
      queryValues.push(floor);
    }
    if (metadata !== undefined) {
      setClauses.push(`metadata = $${queryValues.length + 1}`);
      queryValues.push(metadata);
    }

    setClauses.push('updated_at = CURRENT_TIMESTAMP');

    if (setClauses.length === 1) { // Only updated_at
      return res.status(400).json({ error: 'No fields to update' });
    }

    queryText += setClauses.join(', ');
    queryText += ` WHERE device_id = $${queryValues.length + 1} RETURNING *`;
    queryValues.push(deviceId);

    const query = {
      text: queryText,
      values: queryValues,
    };

    const result = await pool.query(query);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Device not found' });
    }
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating device', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

app.delete('/api/devices/:deviceId', async (req, res) => {
  try {
    const { deviceId } = req.params;
    const query = {
      text: 'DELETE FROM devices WHERE device_id = $1',
      values: [deviceId],
    };
    await pool.query(query);
    res.status(204).send();
  } catch (error) {
    console.error('Error deleting device', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Telemetry
app.post('/api/telemetry', async (req, res) => {
  try {
    const { deviceId, metric, value, unit, timestamp } = req.body;
    const query = {
      text: 'INSERT INTO telemetry(device_id, metric, value, unit, timestamp) VALUES($1, $2, $3, $4, $5) RETURNING *',
      values: [deviceId, metric, value, unit, timestamp],
    };
    const result = await pool.query(query);
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating telemetry', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

app.get('/api/telemetry', async (req, res) => {
  try {
    const { deviceId, metric, startDate, endDate, limit = 100 } = req.query;
    if (!deviceId) {
      return res.status(400).json({ error: 'Missing required field: deviceId' });
    }
    let query = 'SELECT * FROM telemetry WHERE device_id = $1';
    const values = [deviceId];
    if (metric) {
      query += ` AND metric = $${values.length + 1}`;
      values.push(metric);
    }
    if (startDate) {
      query += ` AND timestamp >= $${values.length + 1}`;
      values.push(startDate);
    }
    if (endDate) {
      query += ` AND timestamp <= $${values.length + 1}`;
      values.push(endDate);
    }
    query += ` ORDER BY timestamp DESC LIMIT $${values.length + 1}`;
    values.push(limit);

    const result = await pool.query(query, values);
    res.json({
      deviceId,
      metric,
      data: result.rows,
      count: result.rows.length
    });
  } catch (error) {
    console.error('Error getting telemetry', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Rules
app.post('/api/rules', async (req, res) => {
  try {
    const { name, condition, action, enabled } = req.body;
    const { deviceId, metric, operator, threshold } = condition;
    const query = {
      text: 'INSERT INTO rules(rule_id, name, condition, action, enabled) VALUES($1, $2, $3, $4, $5) RETURNING *',
      values: [`rule-${Date.now()}`, name, { deviceId, metric, operator, threshold }, action, enabled],
    };
    const result = await pool.query(query);
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating rule', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

app.get('/api/rules', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM rules');
    res.json(result.rows);
  } catch (error) {
    console.error('Error getting rules', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

app.delete('/api/rules/:ruleId', async (req, res) => {
  try {
    const { ruleId } = req.params;
    const query = {
      text: 'DELETE FROM rules WHERE rule_id = $1',
      values: [ruleId],
    };
    await pool.query(query);
    res.status(204).send();
  } catch (error) {
    console.error('Error deleting rule', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Alerts
app.get('/api/alerts', async (req, res) => {
  try {
    const { status, severity, startDate, endDate } = req.query;
    let query = 'SELECT * FROM alerts';
    const values = [];
    if (status || severity || startDate || endDate) {
      query += ' WHERE ';
      const conditions = [];
      if (status) {
        conditions.push(`status = $${values.length + 1}`);
        values.push(status);
      }
      if (severity) {
        conditions.push(`severity = $${values.length + 1}`);
        values.push(severity);
      }
      if (startDate) {
        conditions.push(`timestamp >= $${values.length + 1}`);
        values.push(startDate);
      }
      if (endDate) {
        conditions.push(`timestamp <= $${values.length + 1}`);
        values.push(endDate);
      }
      query += conditions.join(' AND ');
    }
    const result = await pool.query(query, values);
    res.json(result.rows);
  } catch (error) {
    console.error('Error getting alerts', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

app.patch('/api/alerts/:alertId', async (req, res) => {
  try {
    const { alertId } = req.params;
    const { status, acknowledgedBy, notes } = req.body;
    const query = {
      text: 'UPDATE alerts SET status = $1, acknowledged_by = $2, notes = $3, acknowledged_at = CURRENT_TIMESTAMP WHERE alert_id = $4 RETURNING *',
      values: [status, acknowledgedBy, notes, alertId],
    };
    const result = await pool.query(query);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Alert not found' });
    }
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating alert', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

app.listen(port, () => {
  console.log(`🚀 Campus IoT backend listening at http://localhost:${port}`);
});
