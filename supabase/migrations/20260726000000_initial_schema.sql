-- 1. Create the profiles table extending auth.users
create table public.profiles (
  id uuid references auth.users(id) on delete cascade not null primary key,
  health_id text unique,
  full_name text,
  avatar_url text,
  phone_number text,
  date_of_birth date,
  gender text,
  emergency_contact text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on profiles
alter table public.profiles enable row level security;

-- Profile Policies
create policy "Public profiles are viewable by everyone."
  on public.profiles for select
  using ( true );

create policy "Users can insert their own profile."
  on public.profiles for insert
  with check ( (select auth.uid()) = id );

create policy "Users can update their own profile."
  on public.profiles for update
  using ( (select auth.uid()) = id )
  with check ( (select auth.uid()) = id );

-- Trigger to create a profile automatically when a new user signs up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, phone_number)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'phone_number'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- 2. Create the clinics table
create table public.clinics (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  category text default 'General Care',
  address text not null,
  image_url text,
  is_open boolean default true,
  rating numeric default 4.5,
  reviews integer default 0,
  wait_time text default '15 min wait',
  hours text default '08:00 AM - 05:00 PM',
  latitude numeric default 40.730610,
  longitude numeric default -73.935242,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on clinics
alter table public.clinics enable row level security;

-- Clinics Policies
create policy "Clinics are viewable by everyone."
  on public.clinics for select
  using ( true );


-- 3. Create the saved_clinics table
create table public.saved_clinics (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  clinic_id uuid references public.clinics(id) on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, clinic_id)
);

-- Enable RLS on saved_clinics
alter table public.saved_clinics enable row level security;

-- Saved Clinics Policies
create policy "Users can view their own saved clinics."
  on public.saved_clinics for select
  to authenticated
  using ( (select auth.uid()) = user_id );

create policy "Users can insert their own saved clinics."
  on public.saved_clinics for insert
  to authenticated
  with check ( (select auth.uid()) = user_id );

create policy "Users can delete their own saved clinics."
  on public.saved_clinics for delete
  to authenticated
  using ( (select auth.uid()) = user_id );


-- 4. Create the medical_history table
create table public.medical_history (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  condition_name text not null,
  notes text,
  date_recorded date,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on medical_history
alter table public.medical_history enable row level security;

-- Medical History Policies
create policy "Users can view their own medical history."
  on public.medical_history for select
  to authenticated
  using ( (select auth.uid()) = user_id );

create policy "Users can insert their own medical history."
  on public.medical_history for insert
  to authenticated
  with check ( (select auth.uid()) = user_id );

create policy "Users can update their own medical history."
  on public.medical_history for update
  to authenticated
  using ( (select auth.uid()) = user_id )
  with check ( (select auth.uid()) = user_id );

create policy "Users can delete their own medical history."
  on public.medical_history for delete
  to authenticated
  using ( (select auth.uid()) = user_id );
