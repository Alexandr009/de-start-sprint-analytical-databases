-- Шаг 5. Миграция данных из STAGING.group_log в линк l_user_group_activity.
--
-- DISTINCT обязателен: в логе на одну пару «пользователь-группа» приходится
-- несколько событий (add / leave / повторный add), а линк хранит связь один раз.
-- История событий пишется в сателлит s_auth_history.

INSERT INTO VT260725214E22__DWH.l_user_group_activity
    (hk_l_user_group_activity, hk_user_id, hk_group_id, load_dt, load_src)
SELECT DISTINCT
    hash(hu.hk_user_id, hg.hk_group_id),
    hu.hk_user_id,
    hg.hk_group_id,
    now() AS load_dt,
    's3'  AS load_src
FROM VT260725214E22__STAGING.group_log AS gl
LEFT JOIN VT260725214E22__DWH.h_users  AS hu ON gl.user_id  = hu.user_id
LEFT JOIN VT260725214E22__DWH.h_groups AS hg ON gl.group_id = hg.group_id;
