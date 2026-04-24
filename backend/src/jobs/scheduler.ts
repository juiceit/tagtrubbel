import cron from 'node-cron';
import pool from '../db/connection';
import { checkSubscription } from '../services/trainChecker';
import type { Subscription } from '../types';

const CHECK_WINDOW_MINUTES = 90;

export function startScheduler(): void {
  cron.schedule('* * * * *', async () => {
    try {
      await runChecks();
    } catch (err) {
      console.error('Scheduler error:', err);
    }
  });

  cron.schedule('0 3 * * *', async () => {
    try {
      await pool.query(
        "DELETE FROM notification_log WHERE sent_at < NOW() - INTERVAL '30 days'",
      );
    } catch (err) {
      console.error('Log cleanup error:', err);
    }
  });

  console.log('Scheduler started.');
}

async function runChecks(): Promise<void> {
  const now = new Date();
  const currentDay = now.getDay() === 0 ? 7 : now.getDay();

  const result = await pool.query<Subscription>(
    `SELECT s.*, d.fcm_token
     FROM subscriptions s
     JOIN devices d ON d.id = s.device_id
     WHERE s.enabled = TRUE
     AND $1 = ANY(s.active_days)`,
    [currentDay],
  );

  const currentMinutes = now.getHours() * 60 + now.getMinutes();

  for (const sub of result.rows) {
    const [h, m] = sub.departure_time.split(':').map(Number);
    const departureMinutes = h * 60 + m;
    const windowStart = departureMinutes - CHECK_WINDOW_MINUTES;

    if (currentMinutes >= windowStart && currentMinutes <= departureMinutes) {
      try {
        await checkSubscription(sub);
      } catch (err) {
        console.error(`Check failed for subscription ${sub.id}:`, err);
      }
    }
  }
}
