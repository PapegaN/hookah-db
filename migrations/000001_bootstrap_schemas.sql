create extension if not exists pgcrypto;

create schema if not exists support;
create schema if not exists catalog;
create schema if not exists inventory;
create schema if not exists sales;

do $$
begin
  if not exists (
    select 1
    from pg_type type
    join pg_namespace namespace on namespace.oid = type.typnamespace
    where type.typname = 'stock_movement_type'
      and namespace.nspname = 'support'
  ) then
    create type support.stock_movement_type as enum (
      'receipt',
      'write_off',
      'consumption',
      'adjustment'
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
    where type.typname = 'order_status'
      and namespace.nspname = 'support'
  ) then
    create type support.order_status as enum (
      'new',
      'in_progress',
      'completed',
      'cancelled'
    );
  end if;
end
$$;
