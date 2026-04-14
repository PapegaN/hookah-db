create schema if not exists media;

create table if not exists media.assets (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid references auth.users (id) on delete set null,
  usage_type text not null,
  status text not null default 'draft',
  bucket_name text not null,
  object_key text not null unique,
  original_file_name text not null,
  mime_type text not null,
  byte_size bigint not null check (byte_size > 0),
  checksum_sha256 text,
  width_px integer check (width_px is null or width_px > 0),
  height_px integer check (height_px is null or height_px > 0),
  public_url text,
  uploaded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ck_media_assets_usage_type
    check (usage_type in ('tobacco_gallery', 'forum_post', 'forum_comment')),
  constraint ck_media_assets_status
    check (status in ('draft', 'uploaded', 'failed', 'deleted'))
);

create index if not exists idx_media_assets_owner_user_id
  on media.assets (owner_user_id);

create index if not exists idx_media_assets_usage_type
  on media.assets (usage_type);

create index if not exists idx_media_assets_status
  on media.assets (status);

drop trigger if exists trg_media_assets_set_updated_at on media.assets;
create trigger trg_media_assets_set_updated_at
before update on media.assets
for each row
execute function support.set_updated_at();
