-- Stores onboarding questionnaire responses.
-- Kept separate from public.users (identity) as this is health/preference data.
-- All required fields reflect questionnaire requirements; optional fields are nullable.

create table public.profiles (
  id uuid primary key references public.users (id) on delete cascade,

  -- -----------------------------------------------------------------------
  -- SECTION 1: About You
  -- -----------------------------------------------------------------------

  gender_identity text not null
    check (gender_identity in (
      'woman', 'non_binary', 'gender_non_conforming', 'self_describe', 'prefer_not_to_say'
    )),
  -- Only populated when gender_identity = 'self_describe'
  gender_identity_description text
    check (char_length(gender_identity_description) <= 50),

  -- At least one selection required; validated at app level
  race_ethnicity text[] not null,
  -- Only populated when 'self_describe' in race_ethnicity
  race_ethnicity_description text
    check (char_length(race_ethnicity_description) <= 75),

  date_of_birth date
    check (
      date_of_birth >= '1900-01-01'
      and date_of_birth <= current_date
    ),

  location text
    check (char_length(location) <= 100),

  insurance_status text not null
    check (insurance_status in ('yes', 'no', 'not_sure')),

  -- -----------------------------------------------------------------------
  -- SECTION 2: Health Background
  -- -----------------------------------------------------------------------

  diagnosed_conditions text[] not null,
  -- Only populated when 'other' in diagnosed_conditions
  diagnosed_conditions_other text
    check (char_length(diagnosed_conditions_other) <= 100),

  family_history text[],
  -- Only populated when 'other' in family_history
  family_history_other text,

  medications_taking text
    check (medications_taking in ('yes', 'no', 'prefer_not_to_say')),
  -- Only populated when medications_taking = 'yes'
  medications_details text
    check (char_length(medications_details) <= 150),

  -- -----------------------------------------------------------------------
  -- SECTION 3: Current Experience
  -- -----------------------------------------------------------------------

  recent_feelings text[] not null,

  current_symptoms text[],
  -- Only populated when 'other' in current_symptoms
  current_symptoms_other text
    check (char_length(current_symptoms_other) <= 100),

  provider_dismissal text not null
    check (provider_dismissal in ('often', 'sometimes', 'rarely', 'never')),

  healthcare_access text not null
    check (healthcare_access in ('very_easy', 'somewhat_easy', 'difficult', 'very_difficult')),

  -- -----------------------------------------------------------------------
  -- SECTION 4: Real Life Context
  -- -----------------------------------------------------------------------

  -- Max 3 selections enforced here and at app level
  health_barriers text[] not null
    check (array_length(health_barriers, 1) <= 3),

  support_level text not null
    check (support_level in ('very_supported', 'somewhat_supported', 'not_supported')),

  -- -----------------------------------------------------------------------
  -- SECTION 5: Goals
  -- -----------------------------------------------------------------------

  -- Max 3 selections enforced here and at app level
  goals text[] not null
    check (array_length(goals, 1) <= 3),

  desired_state text
    check (char_length(desired_state) <= 250),

  -- -----------------------------------------------------------------------
  -- Timestamps
  -- -----------------------------------------------------------------------

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Row Level Security
alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Reuse the handle_updated_at function defined in the users migration
create trigger on_profiles_updated
  before update on public.profiles
  for each row execute procedure public.handle_updated_at();
