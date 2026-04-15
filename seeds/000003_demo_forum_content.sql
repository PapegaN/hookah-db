insert into forum.item_topics (
  section_key,
  reference_item_id,
  description_override,
  created_by_user_id
)
select
  'tobaccos',
  tobacco.id,
  'Supernova как раз тот вкус, про который чаще всего спорят из-за силы холодка и совместимости с десертными миксами.',
  admin_user.id
from catalog.tobaccos tobacco
join auth.users admin_user on admin_user.login = 'admin'
where tobacco.code = 'supernova'
on conflict (section_key, reference_item_id) do update
set
  description_override = excluded.description_override,
  created_by_user_id = excluded.created_by_user_id;

insert into forum.item_topics (
  section_key,
  reference_item_id,
  description_override,
  created_by_user_id
)
select
  'bowls',
  bowl.id,
  'Рабочая чашка под повседневный сервис: хорошо подходит для обсуждения прогрева, плотности укладки и стабильности вкуса.',
  admin_user.id
from equipment.bowls bowl
join equipment.manufacturers manufacturer on manufacturer.id = bowl.manufacturer_id
join auth.users admin_user on admin_user.login = 'admin'
where manufacturer.code = 'cosmo-bowl'
  and bowl.name = 'Turkish Phunnel M'
on conflict (section_key, reference_item_id) do update
set
  description_override = excluded.description_override,
  created_by_user_id = excluded.created_by_user_id;

insert into forum.item_topics (
  section_key,
  reference_item_id,
  description_override,
  created_by_user_id
)
select
  'hookahs',
  hookah.id,
  'Карточка по шахте для обсуждения тяги, удобства в работе и стабильности на длинной посадке.',
  admin_user.id
from equipment.hookahs hookah
join equipment.manufacturers manufacturer on manufacturer.id = hookah.manufacturer_id
join auth.users admin_user on admin_user.login = 'admin'
where manufacturer.code = 'alpha-hookah'
  and hookah.name = 'Model X'
on conflict (section_key, reference_item_id) do update
set
  description_override = excluded.description_override,
  created_by_user_id = excluded.created_by_user_id;

insert into forum.comments (topic_id, author_user_id, body)
select
  topic.id,
  author_user.id,
  source.body
from (
  values
    (
      'tobaccos',
      'supernova',
      'master',
      'В чистом виде вкус мощный, но на сервисе лучше всего раскрывается в паре с ягодой или кремом.'
    ),
    (
      'tobaccos',
      'supernova',
      'client',
      'Для меня это хороший ориентир по холодку: если хочется освежить микс без провала по вкусу, работает стабильно.'
    ),
    (
      'bowls',
      'Turkish Phunnel M',
      'master',
      'Чашка уверенно держит жар и прощает неидеальную укладку, особенно если нужен спокойный сервисный сетап.'
    ),
    (
      'hookahs',
      'Model X',
      'admin',
      'Удачный вариант для зала: тяга предсказуемая, а обслуживание не требует лишней возни.'
    )
) as source(section_key, reference_lookup, author_login, body)
join auth.users author_user on author_user.login = source.author_login
join forum.item_topics topic
  on topic.section_key = source.section_key
join lateral (
  select id
  from (
    select tobacco.id, tobacco.code as lookup_value
    from catalog.tobaccos tobacco
    union all
    select bowl.id, bowl.name as lookup_value
    from equipment.bowls bowl
    union all
    select hookah.id, hookah.name as lookup_value
    from equipment.hookahs hookah
  ) reference_lookup
  where reference_lookup.lookup_value = source.reference_lookup
  limit 1
) reference_item on reference_item.id = topic.reference_item_id
where not exists (
  select 1
  from forum.comments comment_entry
  where comment_entry.topic_id = topic.id
    and comment_entry.author_user_id = author_user.id
    and comment_entry.body = source.body
);

insert into forum.reviews (topic_id, author_user_id, rating_score, body)
select
  topic.id,
  author_user.id,
  source.rating_score,
  source.body
from (
  values
    (
      'tobaccos',
      'supernova',
      'master',
      5,
      'В рабочем режиме вкус очень понятный: легко контролировать холодок и собирать микс под гостя. Лучше всего показывает себя в 10-20% от общей чашки.'
    ),
    (
      'bowls',
      'Turkish Phunnel M',
      'client',
      4,
      'По ощущениям чашка даёт ровный прогрев и не душит вкус. Хороший универсальный вариант без лишней экзотики.'
    ),
    (
      'hookahs',
      'Model X',
      'admin',
      5,
      'Шахта удобна для повседневной работы: легко обслуживать, тяга ровная, а диффузор помогает сделать подачу более мягкой для части гостей.'
    )
) as source(section_key, reference_lookup, author_login, rating_score, body)
join auth.users author_user on author_user.login = source.author_login
join forum.item_topics topic
  on topic.section_key = source.section_key
join lateral (
  select id
  from (
    select tobacco.id, tobacco.code as lookup_value
    from catalog.tobaccos tobacco
    union all
    select bowl.id, bowl.name as lookup_value
    from equipment.bowls bowl
    union all
    select hookah.id, hookah.name as lookup_value
    from equipment.hookahs hookah
  ) reference_lookup
  where reference_lookup.lookup_value = source.reference_lookup
  limit 1
) reference_item on reference_item.id = topic.reference_item_id
on conflict (topic_id, author_user_id) do update
set
  rating_score = excluded.rating_score,
  body = excluded.body,
  is_published = true;
