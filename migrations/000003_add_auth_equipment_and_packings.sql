create extension if not exists citext;

create schema if not exists auth;
create schema if not exists equipment;
create schema if not exists recipes;

do $$
begin
  if not exists (
    select 1
    from pg_type type
    join pg_namespace namespace on namespace.oid = type.typnamespace
    where type.typname = 'bowl_type'
      and namespace.nspname = 'support'
  ) then
    create type support.bowl_type as enum (
      'phunnel',
      'killer',
      'turka',
      'elian'
    );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_type type
    join pg_namespace namespace on namespace.oid = type.typnamespace
    where type.typname = 'bowl_capacity_bucket'
      and namespace.nspname = 'support'
  ) then
    create type support.bowl_capacity_bucket as enum (
      'bucket',
      'large',
      'medium',
      'small',
      'very_small'
    );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_type type
    join pg_namespace namespace on namespace.oid = type.typnamespace
    where type.typname = 'warmup_mode'
      and namespace.nspname = 'support'
  ) then
    create type support.warmup_mode as enum (
      'with_cap',
      'without_cap'
    );
  end if;
end
$$;

create or replace function support.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create table if not exists auth.users (
  id uuid primary key default gen_random_uuid(),
  login citext not null unique,
  password_hash text not null,
  email citext unique,
  telegram_username citext unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ck_auth_users_login_length
    check (char_length(login::text) between 3 and 64),
  constraint ck_auth_users_login_no_spaces
    check (login::text !~ '\s'),
  constraint ck_auth_users_password_hash_not_blank
    check (char_length(trim(password_hash)) > 0),
  constraint ck_auth_users_telegram_username_format
    check (
      telegram_username is null
      or telegram_username::text ~* '^@?[a-z0-9_]{5,32}$'
    )
);

drop trigger if exists trg_auth_users_set_updated_at on auth.users;
create trigger trg_auth_users_set_updated_at
before update on auth.users
for each row
execute function support.set_updated_at();

alter table catalog.tobaccos
  add column if not exists flavor_description text,
  add column if not exists estimated_strength_level smallint,
  add column if not exists brightness_level smallint;

alter table catalog.tobaccos
  drop constraint if exists ck_catalog_tobaccos_estimated_strength_level,
  drop constraint if exists ck_catalog_tobaccos_brightness_level;

alter table catalog.tobaccos
  add constraint ck_catalog_tobaccos_estimated_strength_level
    check (
      estimated_strength_level is null
      or estimated_strength_level between 1 and 5
    ),
  add constraint ck_catalog_tobaccos_brightness_level
    check (
      brightness_level is null
      or brightness_level between 1 and 5
    );

create table if not exists equipment.manufacturers (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists equipment.bowls (
  id uuid primary key default gen_random_uuid(),
  manufacturer_id uuid not null references equipment.manufacturers (id) on delete restrict,
  name text not null,
  bowl_type support.bowl_type not null,
  material text,
  capacity_bucket support.bowl_capacity_bucket not null,
  created_at timestamptz not null default now(),
  unique (manufacturer_id, name)
);

create table if not exists equipment.hookahs (
  id uuid primary key default gen_random_uuid(),
  manufacturer_id uuid not null references equipment.manufacturers (id) on delete restrict,
  name text not null,
  inner_diameter_mm numeric(6, 2) not null check (inner_diameter_mm > 0),
  has_diffuser boolean not null,
  created_at timestamptz not null default now(),
  unique (manufacturer_id, name)
);

create table if not exists equipment.kalauds (
  id uuid primary key default gen_random_uuid(),
  manufacturer_id uuid not null references equipment.manufacturers (id) on delete restrict,
  name text not null,
  material text,
  color text,
  created_at timestamptz not null default now(),
  unique (manufacturer_id, name)
);

create table if not exists equipment.charcoals (
  id uuid primary key default gen_random_uuid(),
  manufacturer_id uuid not null references equipment.manufacturers (id) on delete restrict,
  name text not null,
  size_label text not null,
  created_at timestamptz not null default now(),
  unique (manufacturer_id, name, size_label)
);

create table if not exists recipes.packings (
  id uuid primary key default gen_random_uuid(),
  author_user_id uuid references auth.users (id) on delete set null,
  bowl_id uuid not null references equipment.bowls (id) on delete restrict,
  hookah_id uuid not null references equipment.hookahs (id) on delete restrict,
  kalaud_id uuid not null references equipment.kalauds (id) on delete restrict,
  charcoal_id uuid not null references equipment.charcoals (id) on delete restrict,
  charcoal_count smallint not null check (charcoal_count > 0),
  charcoal_arrangement text not null,
  warmup_duration_minutes smallint not null check (warmup_duration_minutes >= 0),
  warmup_mode support.warmup_mode not null,
  tobacco_weight_grams numeric(6, 2) not null check (tobacco_weight_grams > 0),
  review text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_recipes_packings_set_updated_at on recipes.packings;
create trigger trg_recipes_packings_set_updated_at
before update on recipes.packings
for each row
execute function support.set_updated_at();

create table if not exists recipes.packing_tobaccos (
  packing_id uuid not null references recipes.packings (id) on delete cascade,
  tobacco_id uuid not null references catalog.tobaccos (id) on delete restrict,
  percentage numeric(5, 2) not null check (percentage > 0 and percentage <= 100),
  primary key (packing_id, tobacco_id)
);

create or replace function recipes.validate_packing_tobacco_percentages()
returns trigger
language plpgsql
as $$
declare
  target_packing_id uuid;
  total_percentage numeric(7, 2);
begin
  if tg_op = 'DELETE' then
    target_packing_id := old.packing_id;
  else
    target_packing_id := new.packing_id;
  end if;

  if not exists (
    select 1
    from recipes.packings packing
    where packing.id = target_packing_id
  ) then
    return null;
  end if;

  select coalesce(round(sum(percentage), 2), 0)
    into total_percentage
  from recipes.packing_tobaccos
  where packing_id = target_packing_id;

  if total_percentage <> 100.00 then
    raise exception
      'Packing % must have tobacco percentages summing to 100.00, got %',
      target_packing_id,
      total_percentage;
  end if;

  return null;
end;
$$;

create or replace function recipes.validate_packing_has_components()
returns trigger
language plpgsql
as $$
declare
  component_count integer;
begin
  select count(*)
    into component_count
  from recipes.packing_tobaccos
  where packing_id = new.id;

  if component_count = 0 then
    raise exception
      'Packing % must contain at least one tobacco component',
      new.id;
  end if;

  return null;
end;
$$;

drop trigger if exists trg_recipes_packing_tobaccos_validate_percentages on recipes.packing_tobaccos;
create constraint trigger trg_recipes_packing_tobaccos_validate_percentages
after insert or update or delete on recipes.packing_tobaccos
deferrable initially deferred
for each row
execute function recipes.validate_packing_tobacco_percentages();

drop trigger if exists trg_recipes_packings_validate_components on recipes.packings;
create constraint trigger trg_recipes_packings_validate_components
after insert or update on recipes.packings
deferrable initially deferred
for each row
execute function recipes.validate_packing_has_components();

drop trigger if exists trg_sales_orders_set_updated_at on sales.orders;
create trigger trg_sales_orders_set_updated_at
before update on sales.orders
for each row
execute function support.set_updated_at();

create index if not exists idx_equipment_bowls_manufacturer_id
  on equipment.bowls (manufacturer_id);

create index if not exists idx_equipment_hookahs_manufacturer_id
  on equipment.hookahs (manufacturer_id);

create index if not exists idx_equipment_kalauds_manufacturer_id
  on equipment.kalauds (manufacturer_id);

create index if not exists idx_equipment_charcoals_manufacturer_id
  on equipment.charcoals (manufacturer_id);

create index if not exists idx_recipes_packings_author_user_id
  on recipes.packings (author_user_id);

create index if not exists idx_recipes_packings_bowl_id
  on recipes.packings (bowl_id);

create index if not exists idx_recipes_packings_hookah_id
  on recipes.packings (hookah_id);

create index if not exists idx_recipes_packings_kalaud_id
  on recipes.packings (kalaud_id);

create index if not exists idx_recipes_packings_charcoal_id
  on recipes.packings (charcoal_id);

create index if not exists idx_recipes_packing_tobaccos_tobacco_id
  on recipes.packing_tobaccos (tobacco_id);
