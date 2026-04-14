alter table catalog.tobaccos
  add column if not exists marking_gtin char(14);

create index if not exists idx_catalog_tobaccos_marking_gtin
  on catalog.tobaccos (marking_gtin);

update catalog.tobaccos
set marking_gtin = substring(marking_code from 3 for 14)
where marking_code is not null
  and marking_gtin is null
  and marking_code ~ '^01[0-9]{14}';
