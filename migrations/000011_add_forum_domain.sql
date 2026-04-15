create schema if not exists forum;

create table if not exists forum.item_topics (
  id uuid primary key default gen_random_uuid(),
  section_key text not null,
  reference_item_id uuid not null,
  description_override text,
  cover_asset_id uuid references media.assets (id) on delete set null,
  is_published boolean not null default true,
  created_by_user_id uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ck_forum_item_topics_section_key
    check (
      section_key in (
        'tobaccos',
        'hookahs',
        'bowls',
        'kalauds',
        'charcoals',
        'electric_heads'
      )
    ),
  constraint uq_forum_item_topics_reference unique (section_key, reference_item_id)
);

create index if not exists idx_forum_item_topics_published
  on forum.item_topics (is_published, section_key);

drop trigger if exists trg_forum_item_topics_set_updated_at on forum.item_topics;
create trigger trg_forum_item_topics_set_updated_at
before update on forum.item_topics
for each row
execute function support.set_updated_at();

create table if not exists forum.comments (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references forum.item_topics (id) on delete cascade,
  author_user_id uuid references auth.users (id) on delete set null,
  body text not null,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ck_forum_comments_body_not_empty
    check (length(trim(body)) > 0)
);

create index if not exists idx_forum_comments_topic_id
  on forum.comments (topic_id, created_at desc);

create index if not exists idx_forum_comments_author_user_id
  on forum.comments (author_user_id);

drop trigger if exists trg_forum_comments_set_updated_at on forum.comments;
create trigger trg_forum_comments_set_updated_at
before update on forum.comments
for each row
execute function support.set_updated_at();

create table if not exists forum.reviews (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references forum.item_topics (id) on delete cascade,
  author_user_id uuid references auth.users (id) on delete set null,
  rating_score smallint not null check (rating_score between 1 and 5),
  body text not null,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ck_forum_reviews_body_not_empty
    check (length(trim(body)) > 0),
  constraint uq_forum_reviews_topic_author unique nulls not distinct (topic_id, author_user_id)
);

create index if not exists idx_forum_reviews_topic_id
  on forum.reviews (topic_id, created_at desc);

create index if not exists idx_forum_reviews_author_user_id
  on forum.reviews (author_user_id);

drop trigger if exists trg_forum_reviews_set_updated_at on forum.reviews;
create trigger trg_forum_reviews_set_updated_at
before update on forum.reviews
for each row
execute function support.set_updated_at();

create table if not exists forum.comment_assets (
  comment_id uuid not null references forum.comments (id) on delete cascade,
  asset_id uuid not null references media.assets (id) on delete cascade,
  sort_order integer not null default 0 check (sort_order >= 0),
  created_at timestamptz not null default now(),
  primary key (comment_id, asset_id)
);

create index if not exists idx_forum_comment_assets_asset_id
  on forum.comment_assets (asset_id);

create table if not exists forum.review_assets (
  review_id uuid not null references forum.reviews (id) on delete cascade,
  asset_id uuid not null references media.assets (id) on delete cascade,
  sort_order integer not null default 0 check (sort_order >= 0),
  created_at timestamptz not null default now(),
  primary key (review_id, asset_id)
);

create index if not exists idx_forum_review_assets_asset_id
  on forum.review_assets (asset_id);
