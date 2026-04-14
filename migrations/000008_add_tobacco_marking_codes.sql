alter table catalog.tobaccos
  add column if not exists marking_code text;

create unique index if not exists idx_catalog_tobaccos_marking_code_unique
  on catalog.tobaccos (marking_code)
  where marking_code is not null;
