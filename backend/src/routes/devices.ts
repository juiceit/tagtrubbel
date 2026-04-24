import { Router, type Request, type Response } from 'express';
import pool from '../db/connection';

const router = Router();

router.post('/', async (req: Request, res: Response) => {
  const { fcm_token, platform } = req.body;

  if (!fcm_token || !platform) {
    res.status(400).json({ error: 'fcm_token and platform are required' });
    return;
  }

  if (!['ios', 'android'].includes(platform)) {
    res.status(400).json({ error: 'platform must be ios or android' });
    return;
  }

  const result = await pool.query(
    `INSERT INTO devices (fcm_token, platform)
     VALUES ($1, $2)
     ON CONFLICT (fcm_token) DO UPDATE SET platform = $2
     RETURNING id`,
    [fcm_token, platform],
  );

  res.status(201).json({ id: result.rows[0].id });
});

router.delete('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  await pool.query('DELETE FROM devices WHERE id = $1', [id]);
  res.status(204).send();
});

export default router;
