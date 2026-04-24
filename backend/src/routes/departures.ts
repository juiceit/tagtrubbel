import { Router, type Request, type Response } from 'express';
import { getDepartures, announcementToDeparture } from '../services/trafikverket';

const router = Router();

router.get('/', async (req: Request, res: Response) => {
  const station = req.query.station as string;
  const direction = req.query.direction as string | undefined;

  if (!station) {
    res.status(400).json({ error: 'station query parameter is required' });
    return;
  }

  const now = new Date();
  const fromStr = now.toISOString().replace('Z', '');
  const to = new Date(now.getTime() + 3 * 60 * 60 * 1000);
  const toStr = to.toISOString().replace('Z', '');

  try {
    let announcements = await getDepartures(station, fromStr, toStr);

    if (direction) {
      announcements = announcements.filter((a) => {
        if (!a.ToLocation || a.ToLocation.length === 0) return true;
        return a.ToLocation.some((loc) => loc.LocationName === direction);
      });
    }

    const departures = announcements.map(announcementToDeparture);
    res.json(departures);
  } catch (err) {
    console.error('Departures fetch failed:', err);
    res.status(502).json({ error: 'Failed to fetch departures' });
  }
});

export default router;
