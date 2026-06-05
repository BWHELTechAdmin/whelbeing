-- Replaces public.profiles with public.onboarding_profiles, aligned to the
-- updated onboarding flow (Screens 2–7).
--
-- PHI minimisation policy:
--   • No full name, exact address, or date of birth is stored.
--   • ZIP codes are truncated to the first 3 digits by the client before being
--     sent to the API (zip_prefix is therefore always 3 digits).
--   • Users are identified only by the UUID from auth.users — no email or IP.
--   • No free-text fields; all responses are controlled selections.

-- ── Drop old table ────────────────────────────────────────────────────────────
-- The cascade removes all dependent triggers, policies, and indexes.
drop table if exists public.profiles cascade;

-- ── New onboarding_profiles table ────────────────────────────────────────────

create table public.onboarding_profiles (
  id uuid primary key references public.users (id) on delete cascade,

  -- ─── Screen 2: Identity ────────────────────────────────────────────────────

  -- Optional — user may decline to share any field on this screen.
  racial_identity text
    check (racial_identity in (
      'black_african_american', 'afro_caribbean', 'african_immigrant',
      'multiracial', 'prefer_not_to_say'
    )),

  age_range text
    check (age_range in ('18_24', '25_34', '35_44', '45_54', '55_plus')),

  -- Full ZIP is accepted by the client but only the first 3 digits are stored.
  zip_prefix text
    check (zip_prefix ~ '^\d{3}$'),

  insurance_type text
    check (insurance_type in (
      'medicaid', 'medicare', 'private', 'uninsured', 'not_sure'
    )),

  -- ─── Screen 3: Experience ──────────────────────────────────────────────────

  felt_dismissed text
    check (felt_dismissed in ('yes', 'no', 'not_sure')),

  -- Only relevant when felt_dismissed = 'yes'.
  -- Controlled values: symptoms_brushed_off | told_its_nothing | denied_test |
  --   visit_rushed | no_clear_answers | felt_judged | other
  dismissal_experiences text[],

  -- Only relevant when felt_dismissed = 'yes'.
  dismissal_care_type text
    check (dismissal_care_type in (
      'primary_care', 'ob_gyn', 'emergency_room', 'mental_health', 'specialist'
    )),

  -- ─── Screen 4: Needs ───────────────────────────────────────────────────────

  -- Max 2 selections; enforced at app level before insert/update.
  support_needs text[]
    check (array_length(support_needs, 1) <= 2),

  support_timing text
    check (support_timing in ('before', 'during', 'after', 'all_of_it')),

  -- ─── Screen 5: Real-Time Hook ──────────────────────────────────────────────

  realtime_interest text
    check (realtime_interest in ('yes_absolutely', 'id_try_it', 'not_sure')),

  -- ─── Screen 6: Health Context ──────────────────────────────────────────────

  -- Controlled selections only — no free-text responses accepted.
  -- Values: reproductive_health | unexplained_symptoms | mental_wellness |
  --   heart_health | staying_on_top | prefer_not_to_say
  health_areas text[],

  -- ─── Screen 7: Trust + Consent ────────────────────────────────────────────

  -- Explicit boolean: true = consented, false = declined, null = skipped.
  data_consent boolean,

  -- ─── Timestamps ────────────────────────────────────────────────────────────

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ── Row Level Security ────────────────────────────────────────────────────────

alter table public.onboarding_profiles enable row level security;

create policy "Users can view own onboarding profile"
  on public.onboarding_profiles for select
  using (auth.uid() = id);

create policy "Users can insert own onboarding profile"
  on public.onboarding_profiles for insert
  with check (auth.uid() = id);

create policy "Users can update own onboarding profile"
  on public.onboarding_profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ── updated_at trigger ────────────────────────────────────────────────────────
-- Reuses handle_updated_at() defined in the users migration.

create trigger on_onboarding_profiles_updated
  before update on public.onboarding_profiles
  for each row execute procedure public.handle_updated_at();
