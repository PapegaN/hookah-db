create table if not exists catalog.brands (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  country_code char(2),
  created_at timestamptz not null default now()
);

create table if not exists catalog.product_lines (
  id uuid primary key default gen_random_uuid(),
  brand_id uuid not null references catalog.brands (id) on delete cascade,
  code text not null,
  name text not null,
  strength_level smallint not null check (strength_level between 1 and 5),
  created_at timestamptz not null default now(),
  unique (brand_id, code)
);

create table if not exists catalog.tobaccos (
  id uuid primary key default gen_random_uuid(),
  line_id uuid not null references catalog.product_lines (id) on delete cascade,
  code text not null,
  name text not null,
  flavor_profile text[] not null default '{}',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (line_id, code)
);

create table if not exists inventory.batches (
  id uuid primary key default gen_random_uuid(),
  tobacco_id uuid not null references catalog.tobaccos (id) on delete restrict,
  batch_code text not null unique,
  grams_received numeric(10, 2) not null check (grams_received > 0),
  grams_available numeric(10, 2) not null check (grams_available >= 0),
  purchased_at date,
  expires_at date,
  created_at timestamptz not null default now()
);

create table if not exists inventory.movements (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references inventory.batches (id) on delete cascade,
  movement_type support.stock_movement_type not null,
  quantity_grams numeric(10, 2) not null check (quantity_grams > 0),
  source text not null,
  note text,
  created_at timestamptz not null default now()
);

create table if not exists sales.orders (
  id uuid primary key default gen_random_uuid(),
  order_number integer generated always as identity unique,
  status support.order_status not null default 'new',
  service_type text not null,
  table_label text,
  total_amount numeric(10, 2) not null default 0 check (total_amount >= 0),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists sales.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references sales.orders (id) on delete cascade,
  tobacco_id uuid not null references catalog.tobaccos (id) on delete restrict,
  quantity_grams numeric(10, 2) not null check (quantity_grams > 0),
  unit_price numeric(10, 2) not null check (unit_price >= 0),
  total_price numeric(10, 2) not null check (total_price >= 0),
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists idx_catalog_product_lines_brand_id
  on catalog.product_lines (brand_id);

create index if not exists idx_catalog_tobaccos_line_id
  on catalog.tobaccos (line_id);

create index if not exists idx_inventory_batches_tobacco_id
  on inventory.batches (tobacco_id);

create index if not exists idx_inventory_movements_batch_id
  on inventory.movements (batch_id);

create index if not exists idx_sales_orders_status
  on sales.orders (status);

create index if not exists idx_sales_order_items_order_id
  on sales.order_items (order_id);
