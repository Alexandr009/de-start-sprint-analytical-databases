-- Шаг 6. Наполнение сателлита s_auth_history.
--
-- Источник — STAGING.group_log. Хабы h_users и h_groups нужны, чтобы получить
-- хеш-ключи и через них выйти на нужную строку линка l_user_group_activity.
-- Здесь DISTINCT не нужен: сателлит хранит КАЖДОЕ событие.

INSERT INTO VT260725214E22__DWH.s_auth_history
    (hk_l_user_group_activity, user_id_from, event, event_dt, load_dt, load_src)
SELECT
    luga.hk_l_user_group_activity,
    gl.user_id_from,
    gl.event,
    gl.datetime AS event_dt,
    now()       AS load_dt,
    's3'        AS load_src
FROM VT260725214E22__STAGING.group_log AS gl
LEFT JOIN VT260725214E22__DWH.h_groups AS hg ON gl.group_id = hg.group_id
LEFT JOIN VT260725214E22__DWH.h_users  AS hu ON gl.user_id  = hu.user_id
LEFT JOIN VT260725214E22__DWH.l_user_group_activity AS luga
       ON hg.hk_group_id = luga.hk_group_id
      AND hu.hk_user_id  = luga.hk_user_id;
