import { Router, type Request, type Response } from 'express';
import { searchStations } from '../services/trafikverket';

const router = Router();

router.get('/', async (req: Request, res: Response) => {
  const q = (req.query.q as string) || '';
  if (q.length < 2) {
    res.json([]);
    return;
  }

  try {
    const stations = await searchStations(q);
    res.json(stations);
  } catch (err) {
    console.error('Station search failed:', err);
    res.status(502).json({ error: 'Failed to search stations' });
  }
});

export default router;
