-- Drop existing table if needed (optional, for clean slate)
DROP TABLE IF EXISTS public.clinics CASCADE;

-- Create clinics table
CREATE TABLE public.clinics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    category TEXT DEFAULT 'General Care',
    address TEXT NOT NULL,
    image_url TEXT,
    is_open BOOLEAN DEFAULT true,
    rating NUMERIC DEFAULT 4.5,
    reviews INTEGER DEFAULT 0,
    wait_time TEXT DEFAULT '15 min wait',
    hours TEXT DEFAULT '08:00 AM - 05:00 PM',
    latitude NUMERIC DEFAULT 40.730610,
    longitude NUMERIC DEFAULT -73.935242
);

-- Seed dummy clinics
INSERT INTO public.clinics (name, category, address, image_url, is_open, rating, reviews, wait_time, hours, latitude, longitude)
VALUES 
  ('City Health Urgent Care', 'Urgent Care', '124 Clinical Row, Medical District, NY 10012', 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=600&q=80', true, 4.8, 120, '15 min wait', '08:00 AM - 09:00 PM', 40.7350, -73.9400),
  ('Beacon Wellness Center', 'Pediatrics', '88 Health Blvd, NY 10015', 'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=600&q=80', true, 4.6, 95, '5 min wait', '08:30 AM - 07:00 PM', 40.7250, -73.9280),
  ('Family First Medical', 'General Care', '45 Avenue B, NY 10009', 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=600&q=80', false, 4.9, 210, 'Opens 8:00 AM', '08:00 AM - 05:00 PM', 40.7180, -73.9520);
