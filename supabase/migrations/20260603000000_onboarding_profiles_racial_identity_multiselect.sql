-- Change racial_identity from a single constrained text value to a text array
-- to support multi-select identity disclosure in the onboarding flow.

alter table public.onboarding_profiles
  drop constraint if exists onboarding_profiles_racial_identity_check;

alter table public.onboarding_profiles
  alter column racial_identity type text[]
  using case
    when racial_identity is null then null
    else array[racial_identity]
  end;
