export interface Device {
  id: string;
  fcm_token: string;
  platform: 'ios' | 'android';
  created_at: Date;
}

export interface Subscription {
  id: string;
  device_id: string;
  station_signature: string;
  station_name: string;
  direction_signature: string;
  direction_name: string;
  departure_time: string;
  active_days: number[];
  enabled: boolean;
  created_at: Date;
}

export interface TrainAnnouncement {
  AdvertisedTrainIdent: string;
  AdvertisedTimeAtLocation: string;
  EstimatedTimeAtLocation?: string;
  Canceled: boolean;
  Deviation?: string[];
  ToLocation?: { LocationName: string; Order: number }[];
  TrainOwner: string;
}

export interface Station {
  signature: string;
  name: string;
}

export interface DepartureInfo {
  train_ident: string;
  scheduled_time: string;
  estimated_time: string | null;
  cancelled: boolean;
  deviations: string[];
  destination: string;
}
