create table if not exists catalog.tobacco_tags (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists catalog.tobacco_tag_links (
  tobacco_id uuid not null references catalog.tobaccos (id) on delete cascade,
  tag_id uuid not null references catalog.tobacco_tags (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (tobacco_id, tag_id)
);

create index if not exists idx_catalog_tobacco_tag_links_tag_id
  on catalog.tobacco_tag_links (tag_id);

alter table catalog.tobaccos
  add column if not exists in_stock boolean not null default true;

alter table sales.order_participants
  add column if not exists wants_cooling boolean not null default false,
  add column if not exists wants_mint boolean not null default false,
  add column if not exists wants_spicy boolean not null default false;
