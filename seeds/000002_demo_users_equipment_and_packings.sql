insert into auth.users (
  login,
  password_hash,
  role,
  email,
  telegram_username
)
values
  (
    'admin',
    'scrypt:b85a455cf853a4fd04547ef7273f449a:2fbdae4c4d27789bf0eb7699d53d3774db5f7e0dcc7632751299ca2d90f4dc9505b0769c15bc8fca96183b6e5d27b9ac435a61dd6a075df79234884c95a30d01',
    'admin',
    'admin@example.com',
    'hookah_admin'
  ),
  (
    'master',
    'scrypt:b816a0b6e18deb9e9a1336dd7efa041c:afbc136b27022294b6fda050bf2c5176b25970d5e1fbc811d71d8163ad2a72054c6d23f70d1b661a0eb53381cb17cc2d1bdaf7fe91049acb70f2eee36ed9464a',
    'hookah_master',
    'master@example.com',
    'hookah_master'
  ),
  (
    'client',
    'scrypt:8f514fd82fa8efdc82d2d00eb0ae4973:57eb5fe128828b6dc9cc5669ea574a72cabb94da2f62b0364106359a549287636d2f04330e2d42c1439538207f274369b3f69f9ed367948d4c89c2bc0d2274ba',
    'client',
    'client@example.com',
    'hookah_client'
  )
on conflict (login) do update
set
  password_hash = excluded.password_hash,
  role = excluded.role,
  email = excluded.email,
  telegram_username = excluded.telegram_username;

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
where user_account.login = 'admin'
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
