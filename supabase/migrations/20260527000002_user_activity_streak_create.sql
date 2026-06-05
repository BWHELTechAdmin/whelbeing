-- ── user_activity ────────────────────────────────────────────────────────────
-- Records each calendar day a user opened the app.
-- Primary key (user_id, active_date) means each day is stored exactly once
-- per user regardless of how many times the app is opened.

create table public.user_activity (
  user_id     uuid not null references public.users (id) on delete cascade,
  active_date date not null default current_date,
  primary key (user_id, active_date)
);

alter table public.user_activity enable row level security;

create policy "Users can insert own activity"
  on public.user_activity for insert
  with check (auth.uid() = user_id);

create policy "Users can view own activity"
  on public.user_activity for select
  using (auth.uid() = user_id);

-- ── record_app_open() ─────────────────────────────────────────────────────────
-- Called on every app open. Inserts today for the current user; silently
-- ignores the conflict when called multiple times on the same day.

create or replace function public.record_app_open()
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.user_activity (user_id, active_date)
  values (auth.uid(), current_date)
  on conflict (user_id, active_date) do nothing;
$$;

grant execute on function public.record_app_open to authenticated;

-- ── get_streak() ──────────────────────────────────────────────────────────────
-- Returns the number of consecutive calendar days (ending today or yesterday)
-- on which the current user opened the app.
--
-- Uses the "island and gap" technique:
--   active_date - row_number() produces the same value for each consecutive
--   run of dates, grouping them into an "island". We then pick the island
--   whose most-recent date touches today or yesterday.

create or replace function public.get_streak()
returns int
language sql
security definer
set search_path = ''
as $$
  with ordered as (
    select
      active_date,
      active_date - (row_number() over (order by active_date))::int as grp
    from public.user_activity
    where user_id = auth.uid()
  ),
  islands as (
    select
      grp,
      max(active_date) as last_day,
      count(*)         as streak_len
    from ordered
    group by grp
  )
  select coalesce(
    (
      select streak_len::int
      from islands
      -- Streak is only "active" if it reaches today or yesterday.
      where last_day >= current_date - 1
      order by last_day desc
      limit 1
    ),
    0
  );
$$;

grant execute on function public.get_streak to authenticated;
