-- The original trigger only read `given_name` and `family_name` from OAuth
-- metadata (Google). Email signups pass `username` instead, so first_name was
-- always NULL for email-registered users. This replaces the function to fall
-- back to `username` when `given_name` is absent.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.users (id, first_name, last_name)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'given_name',  -- Google / Apple OAuth
      new.raw_user_meta_data ->> 'username'      -- Email signup
    ),
    new.raw_user_meta_data ->> 'family_name'     -- Google / Apple OAuth only
  );
  return new;
end;
$$;
