insert into auth.users (
  login,
  password_hash,
  email,
  telegram_username
)
values (
  'demo.admin',
  '$argon2id$v=19$m=65536,t=3,p=4$demo-salt$demo-password-hash-placeholder',
  'admin@example.com',
  'demo_admin'
)
on conflict (login) do nothing;

insert into equipment.manufacturers (code, name)
values
  ('cosmo-bowl', 'Cosmo Bowl'),
  ('alpha-hookah', 'Alpha Hookah'),
  ('kaloud', 'Kaloud'),
  ('cocoloco', 'CocoLoco')
on conflict (code) do nothing;

insert into equipment.bowls (
  manufacturer_id,
  name,
  bowl_type,
  material,
  capacity_bucket
)
select manufacturer.id, 'Turkish Phunnel M', 'phunnel', 'clay', 'medium'
from equipment.manufacturers manufacturer
where manufacturer.code = 'cosmo-bowl'
on conflict (manufacturer_id, name) do nothing;

insert into equipment.hookahs (
  manufacturer_id,
  name,
  inner_diameter_mm,
  has_diffuser
)
select manufacturer.id, 'Model X', 13.00, true
from equipment.manufacturers manufacturer
where manufacturer.code = 'alpha-hookah'
on conflict (manufacturer_id, name) do nothing;

insert into equipment.kalauds (
  manufacturer_id,
  name,
  material,
  color
)
select manufacturer.id, 'Lotus I+', 'aluminum', 'black'
from equipment.manufacturers manufacturer
where manufacturer.code = 'kaloud'
on conflict (manufacturer_id, name) do nothing;

insert into equipment.charcoals (
  manufacturer_id,
  name,
  size_label
)
select manufacturer.id, 'Cube', '25mm'
from equipment.manufacturers manufacturer
where manufacturer.code = 'cocoloco'
on conflict (manufacturer_id, name, size_label) do nothing;

insert into recipes.packings (
  author_user_id,
  bowl_id,
  hookah_id,
  kalaud_id,
  charcoal_id,
  charcoal_count,
  charcoal_arrangement,
  warmup_duration_minutes,
  warmup_mode,
  tobacco_weight_grams,
  review
)
select
  user_account.id,
  bowl.id,
  hookah.id,
  kalaud.id,
  charcoal.id,
  3,
  'Two coals on the edge and one centered for warm-up.',
  6,
  'with_cap',
  17.50,
  'Demo cooling mix with dessert support for local development.'
from auth.users user_account
join equipment.bowls bowl
  on bowl.name = 'Turkish Phunnel M'
join equipment.manufacturers bowl_manufacturer
  on bowl_manufacturer.id = bowl.manufacturer_id
  and bowl_manufacturer.code = 'cosmo-bowl'
join equipment.hookahs hookah
  on hookah.name = 'Model X'
join equipment.manufacturers hookah_manufacturer
  on hookah_manufacturer.id = hookah.manufacturer_id
  and hookah_manufacturer.code = 'alpha-hookah'
join equipment.kalauds kalaud
  on kalaud.name = 'Lotus I+'
join equipment.manufacturers kalaud_manufacturer
  on kalaud_manufacturer.id = kalaud.manufacturer_id
  and kalaud_manufacturer.code = 'kaloud'
join equipment.charcoals charcoal
  on charcoal.name = 'Cube'
  and charcoal.size_label = '25mm'
join equipment.manufacturers charcoal_manufacturer
  on charcoal_manufacturer.id = charcoal.manufacturer_id
  and charcoal_manufacturer.code = 'cocoloco'
where user_account.login = 'demo.admin'
  and not exists (
    select 1
    from recipes.packings packing
    where packing.review = 'Demo cooling mix with dessert support for local development.'
  );

insert into recipes.packing_tobaccos (
  packing_id,
  tobacco_id,
  percentage
)
select packing.id, tobacco.id, source.percentage
from (
  values
    ('supernova', 70.00),
    ('kiwi-smoothie', 30.00)
) as source(tobacco_code, percentage)
join recipes.packings packing
  on packing.review = 'Demo cooling mix with dessert support for local development.'
join catalog.tobaccos tobacco
  on tobacco.code = source.tobacco_code
on conflict (packing_id, tobacco_id) do nothing;
