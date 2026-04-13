insert into catalog.brands (code, name, country_code)
values
  ('darkside', 'Darkside', 'RU'),
  ('musthave', 'Musthave', 'RU')
on conflict (code) do nothing;

insert into catalog.product_lines (brand_id, code, name, strength_level)
select brand.id, source.code, source.name, source.strength_level
from (
  values
    ('darkside', 'core', 'Core', 4),
    ('musthave', 'classic', 'Classic', 3)
) as source(brand_code, code, name, strength_level)
join catalog.brands brand on brand.code = source.brand_code
on conflict (brand_id, code) do nothing;

insert into catalog.tobaccos (line_id, code, name, flavor_profile)
select product_line.id, source.code, source.name, source.flavor_profile
from (
  values
    ('darkside', 'core', 'supernova', 'Supernova', array['mint', 'cooling']),
    ('musthave', 'classic', 'kiwi-smoothie', 'Kiwi Smoothie', array['kiwi', 'cream'])
) as source(brand_code, line_code, code, name, flavor_profile)
join catalog.product_lines product_line on product_line.code = source.line_code
join catalog.brands brand on brand.id = product_line.brand_id and brand.code = source.brand_code
on conflict (line_id, code) do nothing;

insert into inventory.batches (
  tobacco_id,
  batch_code,
  grams_received,
  grams_available,
  purchased_at
)
select tobacco.id, source.batch_code, source.grams_received, source.grams_available, source.purchased_at
from (
  values
    ('darkside', 'core', 'supernova', 'DS-APR-001', 250.00, 210.00, date '2026-04-10'),
    ('musthave', 'classic', 'kiwi-smoothie', 'MH-APR-004', 200.00, 200.00, date '2026-04-11')
) as source(
  brand_code,
  line_code,
  tobacco_code,
  batch_code,
  grams_received,
  grams_available,
  purchased_at
)
join catalog.tobaccos tobacco on tobacco.code = source.tobacco_code
join catalog.product_lines product_line on product_line.id = tobacco.line_id and product_line.code = source.line_code
join catalog.brands brand on brand.id = product_line.brand_id and brand.code = source.brand_code
on conflict (batch_code) do nothing;

insert into sales.orders (service_type, table_label, total_amount, notes)
select 'hall', 'Table 7', 1250.00, 'Демо-заказ для локальной среды'
where not exists (
  select 1
  from sales.orders
  where notes = 'Демо-заказ для локальной среды'
);
