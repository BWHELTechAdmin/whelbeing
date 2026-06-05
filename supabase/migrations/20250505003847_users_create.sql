-- Create a public profiles table that extends Supabase Auth users.
-- auth.users is managed by Supabase and stores credentials/OAuth tokens.
-- This table stores app-level profile data linked to that auth record.

create table public.users (
  id           uuid primary key references auth.users (id) on delete cascade,
  first_name   text,
  last_name    text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
  -- email and provider are omitted: use auth.users.email and
  -- auth.users.raw_app_meta_data->>'provider' directly to avoid duplication.
  -- avatar_url omitted: not used in the app.
);

-- Enable Row Level Security
alter table public.users enable row level security;

-- Users can read their own profile
create policy "Users can view own profile"
  on public.users for select
  using (auth.uid() = id);

-- Users can update their own profile
create policy "Users can update own profile"
  on public.users for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Auto-update updated_at on row change
create function public.handle_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger on_users_updated
  before update on public.users
  for each row execute procedure public.handle_updated_at();

-- Automatically create a profile row when a new user signs up.
-- Pulls first_name and last_name from OAuth metadata.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.users (id, first_name, last_name)
  values (
    new.id,
    new.raw_user_meta_data ->> 'given_name',   -- Google; Apple sends on first login only
    new.raw_user_meta_data ->> 'family_name'   -- Google; Apple sends on first login only
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
