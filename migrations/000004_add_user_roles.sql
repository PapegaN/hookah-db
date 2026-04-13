do $$
begin
  if not exists (
    select 1
    from pg_type type
    join pg_namespace namespace on namespace.oid = type.typnamespace
    where type.typname = 'user_role'
      and namespace.nspname = 'support'
  ) then
    create type support.user_role as enum (
      'admin',
      'hookah_master',
      'client'
    );
  end if;
end
$$;

alter table auth.users
  add column if not exists role support.user_role not null default 'client';

create index if not exists idx_auth_users_role
  on auth.users (role);
