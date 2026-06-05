-- Update handle_new_user so email sign-ups can supply first_name and last_name
-- as separate metadata keys instead of a single username field.

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
      new.raw_user_meta_data ->> 'given_name',   -- Google / Apple OAuth
      new.raw_user_meta_data ->> 'first_name'    -- Email sign-up
    ),
    coalesce(
      new.raw_user_meta_data ->> 'family_name',  -- Google / Apple OAuth
      new.raw_user_meta_data ->> 'last_name'     -- Email sign-up
    )
  );
  return new;
end;
$$;
