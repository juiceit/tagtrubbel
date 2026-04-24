import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import devicesRouter from './routes/devices';
import subscriptionsRouter from './routes/subscriptions';
import stationsRouter from './routes/stations';
import departuresRouter from './routes/departures';
import { startScheduler } from './jobs/scheduler';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.use('/api/devices', devicesRouter);
app.use('/api/subscriptions', subscriptionsRouter);
app.use('/api/stations', stationsRouter);
app.use('/api/departures', departuresRouter);

app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.listen(PORT, () => {
  console.log(`Tågtrubbel backend running on port ${PORT}`);
  startScheduler();
});
