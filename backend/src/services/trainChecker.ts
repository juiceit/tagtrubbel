import pool from '../db/connection';
import { getDepartures, announcementToDeparture } from './trafikverket';
import { sendPushNotification } from './notifications';
import type { Subscription, TrainAnnouncement } from '../types';

const LOOK_BACK_MINUTES = 90;
const WARNING_THRESHOLD = 0.5;

export async function checkSubscription(sub: Subscription): Promise<void> {
  const now = new Date();
  const [hours, minutes] = sub.departure_time.split(':').map(Number);

  const departureDate = new Date(now);
  departureDate.setHours(hours, minutes, 0, 0);

  const fromDate = new Date(departureDate);
  fromDate.setMinutes(fromDate.getMinutes() - LOOK_BACK_MINUTES);

  const toDate = new Date(departureDate);
  toDate.setMinutes(toDate.getMinutes() + 1);

  const fromStr = fromDate.toISOString().replace('Z', '');
  const toStr = toDate.toISOString().replace('Z', '');

  let announcements: TrainAnnouncement[];
  try {
    announcements = await getDepartures(sub.station_signature, fromStr, toStr);
  } catch (err) {
    console.error(`Failed to fetch departures for ${sub.station_signature}:`, err);
    return;
  }

  const relevantDirection = announcements.filter((a) => {
    if (!a.ToLocation || a.ToLocation.length === 0) return true;
    return a.ToLocation.some(
      (loc) => loc.LocationName === sub.direction_signature,
    );
  });

  if (relevantDirection.length === 0) return;

  const departures = relevantDirection.map(announcementToDeparture);

  const userTrain = departures.find((d) => {
    const scheduled = new Date(d.scheduled_time);
    return (
      scheduled.getHours() === hours &&
      Math.abs(scheduled.getMinutes() - minutes) <= 2
    );
  });

  if (userTrain?.cancelled) {
    await notify(sub, userTrain.train_ident, 'cancelled',
      `Tåg ${userTrain.train_ident} till ${sub.direction_name} kl ${sub.departure_time} är inställt.`);
    return;
  }

  if (userTrain?.estimated_time) {
    const scheduled = new Date(userTrain.scheduled_time);
    const estimated = new Date(userTrain.estimated_time);
    const delayMin = Math.round((estimated.getTime() - scheduled.getTime()) / 60000);
    if (delayMin >= 3) {
      await notify(sub, userTrain.train_ident, 'delayed',
        `Tåg ${userTrain.train_ident} till ${sub.direction_name} beräknas bli ${delayMin} min försenat.`);
      return;
    }
  }

  const cancelledOrDelayed = departures.filter((d) => {
    if (d.cancelled) return true;
    if (d.estimated_time) {
      const s = new Date(d.scheduled_time).getTime();
      const e = new Date(d.estimated_time).getTime();
      return (e - s) / 60000 >= 3;
    }
    return false;
  });

  const ratio = cancelledOrDelayed.length / departures.length;
  if (ratio >= WARNING_THRESHOLD && departures.length >= 2) {
    await notify(sub, 'multiple', 'warning',
      `Störningar på sträckan ${sub.station_name} → ${sub.direction_name}. Din avgång kl ${sub.departure_time} kan bli påverkad.`);
  }
}

async function notify(
  sub: Subscription,
  trainIdent: string,
  type: 'delayed' | 'cancelled' | 'warning',
  message: string,
): Promise<void> {
  const today = new Date().toISOString().slice(0, 10);

  const existing = await pool.query(
    `SELECT 1 FROM notification_log
     WHERE subscription_id = $1 AND train_ident = $2 AND notification_type = $3
     AND sent_at::date = $4::date`,
    [sub.id, trainIdent, type, today],
  );
  if (existing.rows.length > 0) return;

  const device = await pool.query('SELECT fcm_token FROM devices WHERE id = $1', [
    sub.device_id,
  ]);
  if (device.rows.length === 0) return;

  const title = type === 'cancelled'
    ? 'Inställt tåg'
    : type === 'delayed'
    ? 'Försenat tåg'
    : 'Möjliga störningar';

  const sent = await sendPushNotification(device.rows[0].fcm_token, title, message);

  if (sent) {
    await pool.query(
      `INSERT INTO notification_log (subscription_id, train_ident, notification_type, message)
       VALUES ($1, $2, $3, $4)`,
      [sub.id, trainIdent, type, message],
    );
  }
}
