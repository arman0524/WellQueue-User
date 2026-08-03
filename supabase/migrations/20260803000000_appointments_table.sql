-- Appointments table to store all bookings made via the AI calling agent
create table public.appointments (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  clinic_id uuid references public.clinics(id) on delete cascade not null,
  
  -- Patient details (may differ from user if booking for someone else)
  patient_name text not null,
  patient_phone text,
  patient_email text,
  relationship text default 'self',  -- 'self', 'spouse', 'child', 'parent', 'other'
  
  -- Appointment details
  consultation_type text default 'General Checkup',  -- 'General Checkup' or 'Follow-up'
  appointment_date date not null,
  appointment_time time not null,
  status text default 'upcoming',  -- 'upcoming', 'completed', 'cancelled'
  
  -- Cal.com reference for cancel/reschedule
  cal_booking_uid text,
  
  -- Metadata
  notes text,
  created_at timestamptz default timezone('utc'::text, now()) not null,
  updated_at timestamptz default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.appointments enable row level security;

-- Users can view their own appointments
create policy "Users can view their own appointments."
  on public.appointments for select
  to authenticated
  using ( (select auth.uid()) = user_id );

-- Users can insert their own appointments
create policy "Users can insert their own appointments."
  on public.appointments for insert
  to authenticated
  with check ( (select auth.uid()) = user_id );

-- Users can update their own appointments (for cancel/reschedule)
create policy "Users can update their own appointments."
  on public.appointments for update
  to authenticated
  using ( (select auth.uid()) = user_id )
  with check ( (select auth.uid()) = user_id );

-- Service role can insert appointments (for Make.com webhook)
-- This is handled by the service_role key, which bypasses RLS.

-- Index for faster queries
create index idx_appointments_user_id on public.appointments(user_id);
create index idx_appointments_status on public.appointments(status);
create index idx_appointments_date on public.appointments(appointment_date);

-- Function to auto-update the updated_at timestamp
create or replace function public.handle_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger on_appointment_updated
  before update on public.appointments
  for each row execute procedure public.handle_updated_at();
