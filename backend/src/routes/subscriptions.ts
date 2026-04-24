import { Router, type Request, type Response } from 'express';
import pool from '../db/connection';

const router = Router();

router.get('/', async (req: Request, res: Response) => {
  const deviceId = req.headers['x-device-id'];
  if (!deviceId) {
    res.status(400).json({ error: 'X-Device-Id header is required' });
    return;
  }

  const result = await pool.query(
    'SELECT * FROM subscriptions WHERE device_id = $1 ORDER BY departure_time',
    [deviceId],
  );
  res.json(result.rows);
});

router.post('/', async (req: Request, res: Response) => {
  const deviceId = req.headers['x-device-id'];
  if (!deviceId) {
    res.status(400).json({ error: 'X-Device-Id header is required' });
    return;
  }

  const {
    station_signature,
    station_name,
    direction_signature,
    direction_name,
    departure_time,
    active_days,
  } = req.body;

  if (
    !station_signature ||
    !station_name ||
    !direction_signature ||
    !direction_name ||
    !departure_time ||
    !active_days?.length
  ) {
    res.status(400).json({ error: 'Missing required fields' });
    return;
  }

  const result = await pool.query(
    `INSERT INTO subscriptions
     (device_id, station_signature, station_name, direction_signature, direction_name, departure_time, active_days)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
    [deviceId, station_signature, station_name, direction_signature, direction_name, departure_time, active_days],
  );
  res.status(201).json(result.rows[0]);
});

router.put('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  const {
    station_signature,
    station_name,
    direction_signature,
    direction_name,
    departure_time,
    active_days,
    enabled,
  } = req.body;

  const result = await pool.query(
    `UPDATE subscriptions SET
       station_signature = COALESCE($2, station_signature),
       station_name = COALESCE($3, station_name),
       direction_signature = COALESCE($4, direction_signature),
       direction_name = COALESCE($5, direction_name),
       departure_time = COALESCE($6, departure_time),
       active_days = COALESCE($7, active_days),
       enabled = COALESCE($8, enabled)
     WHERE id = $1
     RETURNING *`,
    [id, station_signature, station_name, direction_signature, direction_name, departure_time, active_days, enabled],
  );

  if (result.rows.length === 0) {
    res.status(404).json({ error: 'Subscription not found' });
    return;
  }
  res.json(result.rows[0]);
});

router.delete('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  const result = await pool.query(
    'DELETE FROM subscriptions WHERE id = $1 RETURNING id',
    [id],
  );
  if (result.rows.length === 0) {
    res.status(404).json({ error: 'Subscription not found' });
    return;
  }
  res.status(204).send();
});

export default router;
