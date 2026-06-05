-- Add optional profile fields to public.users.
-- phone       — nullable, no format constraint (international formats vary).
-- date_of_birth — nullable date; validated at app level before insert.

alter table public.users
  add column if not exists phone        text,
  add column if not exists date_of_birth date;
