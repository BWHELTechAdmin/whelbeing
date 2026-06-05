-- Health records: visits, labs, and symptom logs tracked by the user.
-- Each record belongs to a single user and is protected by RLS.

create table public.health_records (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.users (id) on delete cascade,
  type          text not null
    check (type in ('visit', 'lab', 'symptom_log')),
  record_date   date not null,
  title         text not null,
  notes         text,
  status        text not null default 'none'
    check (status in ('none', 'flagged', 'missing_result')),
  ai_suggestion text,
  created_at    timestamptz not null default now()
);

-- Enable Row Level Security
alter table public.health_records enable row level security;

create policy "Users can view own health records"
  on public.health_records for select
  using (auth.uid() = user_id);

create policy "Users can insert own health records"
  on public.health_records for insert
  with check (auth.uid() = user_id);

create policy "Users can update own health records"
  on public.health_records for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own health records"
  on public.health_records for delete
  using (auth.uid() = user_id);

-- Efficient per-user queries ordered by date
create index health_records_user_date_idx
  on public.health_records (user_id, record_date desc);
