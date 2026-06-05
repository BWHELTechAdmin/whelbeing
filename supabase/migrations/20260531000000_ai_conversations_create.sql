-- AI conversations: persisted chat sessions for the "Recent AI Activity" section.
-- Each row represents one chat session tied to a specific AI mode.

create table public.ai_conversations (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.users (id) on delete cascade,
  mode            text not null
    check (mode in ('symptom_navigator', 'appointment_prep', 'lab_interpreter', 'care_gap')),
  title           text not null,
  messages        jsonb not null default '[]',
  last_message_at timestamptz not null default now(),
  created_at      timestamptz not null default now()
);

-- Enable Row Level Security
alter table public.ai_conversations enable row level security;

create policy "Users can view own ai conversations"
  on public.ai_conversations for select
  using (auth.uid() = user_id);

create policy "Users can insert own ai conversations"
  on public.ai_conversations for insert
  with check (auth.uid() = user_id);

create policy "Users can update own ai conversations"
  on public.ai_conversations for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own ai conversations"
  on public.ai_conversations for delete
  using (auth.uid() = user_id);

-- Efficient per-user queries ordered by most recent activity
create index ai_conversations_user_date_idx
  on public.ai_conversations (user_id, last_message_at desc);
