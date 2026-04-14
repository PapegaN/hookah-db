do $$
begin
  if not exists (
    select 1
    from pg_type type
    join pg_namespace namespace on namespace.oid = type.typnamespace
    where type.typname = 'heating_system_type'
      and namespace.nspname = 'support'
  ) then
    create type support.heating_system_type as enum ('coal', 'electric');
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_type type
    join pg_namespace namespace on namespace.oid = type.typnamespace
    where type.typname = 'packing_style'
      and namespace.nspname = 'support'
  ) then
    create type support.packing_style as enum (
      'layers',
      'sectors',
      'kompot',
      'custom'
    );
  end if;
end
$$;

create table if not exists equipment.electric_heads (
  id uuid primary key default gen_random_uuid(),
  manufacturer_id uuid not null references equipment.manufacturers (id) on delete restrict,
  name text not null,
  created_at timestamptz not null default now(),
  unique (manufacturer_id, name)
);

create index if not exists idx_equipment_electric_heads_manufacturer_id
  on equipment.electric_heads (manufacturer_id);

alter table sales.orders
  add column if not exists requested_heating_system_type support.heating_system_type,
  add column if not exists requested_packing_style support.packing_style,
  add column if not exists requested_custom_packing_style text,
  add column if not exists requested_hookah_id uuid references equipment.hookahs (id) on delete set null,
  add column if not exists requested_bowl_id uuid references equipment.bowls (id) on delete set null,
  add column if not exists requested_kalaud_id uuid references equipment.kalauds (id) on delete set null,
  add column if not exists requested_charcoal_id uuid references equipment.charcoals (id) on delete set null,
  add column if not exists requested_electric_head_id uuid references equipment.electric_heads (id) on delete set null,
  add column if not exists requested_charcoal_count smallint,
  add column if not exists requested_warmup_mode support.warmup_mode,
  add column if not exists requested_warmup_duration_minutes smallint,
  add column if not exists actual_heating_system_type support.heating_system_type,
  add column if not exists actual_packing_style support.packing_style,
  add column if not exists actual_custom_packing_style text,
  add column if not exists actual_hookah_id uuid references equipment.hookahs (id) on delete set null,
  add column if not exists actual_bowl_id uuid references equipment.bowls (id) on delete set null,
  add column if not exists actual_kalaud_id uuid references equipment.kalauds (id) on delete set null,
  add column if not exists actual_charcoal_id uuid references equipment.charcoals (id) on delete set null,
  add column if not exists actual_electric_head_id uuid references equipment.electric_heads (id) on delete set null,
  add column if not exists actual_charcoal_count smallint,
  add column if not exists actual_warmup_mode support.warmup_mode,
  add column if not exists actual_warmup_duration_minutes smallint;

alter table sales.orders
  drop constraint if exists ck_sales_orders_requested_charcoal_count,
  drop constraint if exists ck_sales_orders_actual_charcoal_count,
  drop constraint if exists ck_sales_orders_requested_warmup_duration_minutes,
  drop constraint if exists ck_sales_orders_actual_warmup_duration_minutes;

alter table sales.orders
  add constraint ck_sales_orders_requested_charcoal_count
    check (requested_charcoal_count is null or requested_charcoal_count > 0),
  add constraint ck_sales_orders_actual_charcoal_count
    check (actual_charcoal_count is null or actual_charcoal_count > 0),
  add constraint ck_sales_orders_requested_warmup_duration_minutes
    check (
      requested_warmup_duration_minutes is null
      or requested_warmup_duration_minutes >= 0
    ),
  add constraint ck_sales_orders_actual_warmup_duration_minutes
    check (
      actual_warmup_duration_minutes is null
      or actual_warmup_duration_minutes >= 0
    );

alter table sales.order_participant_tobaccos
  add column if not exists percentage numeric(5, 2);

update sales.order_participant_tobaccos participant_tobacco
set percentage = subquery.percentage
from (
  select
    participant_id,
    round(100.0 / count(*) over (partition by participant_id), 2) as percentage,
    tobacco_id
  from sales.order_participant_tobaccos
) as subquery
where participant_tobacco.participant_id = subquery.participant_id
  and participant_tobacco.tobacco_id = subquery.tobacco_id
  and participant_tobacco.percentage is null;

alter table sales.order_participant_tobaccos
  alter column percentage set not null;

alter table sales.order_participant_tobaccos
  drop constraint if exists ck_sales_order_participant_tobaccos_percentage;

alter table sales.order_participant_tobaccos
  add constraint ck_sales_order_participant_tobaccos_percentage
    check (percentage > 0 and percentage <= 100);

alter table sales.order_actual_tobaccos
  add column if not exists percentage numeric(5, 2);

update sales.order_actual_tobaccos actual_tobacco
set percentage = subquery.percentage
from (
  select
    order_id,
    round(100.0 / count(*) over (partition by order_id), 2) as percentage,
    tobacco_id
  from sales.order_actual_tobaccos
) as subquery
where actual_tobacco.order_id = subquery.order_id
  and actual_tobacco.tobacco_id = subquery.tobacco_id
  and actual_tobacco.percentage is null;

alter table sales.order_actual_tobaccos
  alter column percentage set not null;

alter table sales.order_actual_tobaccos
  drop constraint if exists ck_sales_order_actual_tobaccos_percentage;

alter table sales.order_actual_tobaccos
  add constraint ck_sales_order_actual_tobaccos_percentage
    check (percentage > 0 and percentage <= 100);

create table if not exists support.backup_audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references auth.users (id) on delete set null,
  resource_name text not null,
  action_name text not null,
  schema_version text not null,
  checksum_sha256 text not null,
  item_count integer not null default 0,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_support_backup_audit_events_actor_user_id
  on support.backup_audit_events (actor_user_id);

create index if not exists idx_support_backup_audit_events_created_at
  on support.backup_audit_events (created_at desc);
