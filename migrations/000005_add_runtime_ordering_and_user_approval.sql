do $$
begin
  if not exists (
    select 1
    from pg_type type
    join pg_namespace namespace on namespace.oid = type.typnamespace
    where type.typname = 'table_approval_status'
      and namespace.nspname = 'support'
  ) then
    create type support.table_approval_status as enum ('pending', 'approved');
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_type type
    join pg_namespace namespace on namespace.oid = type.typnamespace
    where type.typname = 'order_timeline_event_type'
      and namespace.nspname = 'support'
  ) then
    create type support.order_timeline_event_type as enum (
      'created',
      'participant_joined',
      'participant_table_approved',
      'started',
      'delivered',
      'feedback_received'
    );
  end if;
end
$$;

alter table auth.users
  add column if not exists is_approved boolean not null default false,
  add column if not exists approved_at timestamptz,
  add column if not exists approved_by_user_id uuid references auth.users (id) on delete set null;

create index if not exists idx_auth_users_is_approved
  on auth.users (is_approved);

create index if not exists idx_auth_users_approved_by_user_id
  on auth.users (approved_by_user_id);

do $$
begin
  alter type support.order_status add value if not exists 'ready_for_feedback';
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  alter type support.order_status add value if not exists 'rated';
exception
  when duplicate_object then null;
end
$$;

alter table sales.orders
  add column if not exists accepted_by_user_id uuid references auth.users (id) on delete set null,
  add column if not exists delivered_at timestamptz,
  add column if not exists feedback_at timestamptz,
  add column if not exists packing_comment text;

create index if not exists idx_sales_orders_table_label
  on sales.orders (table_label);

create index if not exists idx_sales_orders_accepted_by_user_id
  on sales.orders (accepted_by_user_id);

create table if not exists sales.order_participants (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references sales.orders (id) on delete cascade,
  client_user_id uuid not null references auth.users (id) on delete restrict,
  description text not null,
  joined_at timestamptz not null default now(),
  table_approval_status support.table_approval_status not null default 'pending',
  table_approved_at timestamptz,
  table_approved_by_user_id uuid references auth.users (id) on delete set null,
  unique (order_id, client_user_id)
);

create table if not exists sales.order_participant_tobaccos (
  participant_id uuid not null references sales.order_participants (id) on delete cascade,
  tobacco_id uuid not null references catalog.tobaccos (id) on delete restrict,
  primary key (participant_id, tobacco_id)
);

create table if not exists sales.order_actual_tobaccos (
  order_id uuid not null references sales.orders (id) on delete cascade,
  tobacco_id uuid not null references catalog.tobaccos (id) on delete restrict,
  primary key (order_id, tobacco_id)
);

create table if not exists sales.order_feedbacks (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references sales.orders (id) on delete cascade,
  participant_id uuid not null unique references sales.order_participants (id) on delete cascade,
  rating_score smallint not null check (rating_score between 1 and 5),
  rating_review text,
  submitted_at timestamptz not null default now()
);

create table if not exists sales.order_timeline (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references sales.orders (id) on delete cascade,
  event_type support.order_timeline_event_type not null,
  status support.order_status not null,
  actor_user_id uuid references auth.users (id) on delete set null,
  note text not null,
  occurred_at timestamptz not null default now()
);

create index if not exists idx_sales_order_participants_order_id
  on sales.order_participants (order_id);

create index if not exists idx_sales_order_participants_client_user_id
  on sales.order_participants (client_user_id);

create index if not exists idx_sales_order_participant_tobaccos_tobacco_id
  on sales.order_participant_tobaccos (tobacco_id);

create index if not exists idx_sales_order_actual_tobaccos_tobacco_id
  on sales.order_actual_tobaccos (tobacco_id);

create index if not exists idx_sales_order_feedbacks_order_id
  on sales.order_feedbacks (order_id);

create index if not exists idx_sales_order_timeline_order_id
  on sales.order_timeline (order_id, occurred_at desc);
