-- Шаг 7.3. Ответ бизнесу: конверсия из вступления в группу в первое сообщение
-- по 10 самым старым группам, отсортировано по убыванию конверсии.
--
-- ::numeric обязателен — без него Vertica выполнит целочисленное деление
-- и все конверсии окажутся нулями.

WITH user_group_log AS (
    SELECT luga.hk_group_id,
           count(DISTINCT luga.hk_user_id) AS cnt_added_users
    FROM VT260725214E22__DWH.l_user_group_activity AS luga
    LEFT JOIN VT260725214E22__DWH.s_auth_history AS sah
           ON luga.hk_l_user_group_activity = sah.hk_l_user_group_activity
    WHERE sah.event = 'add'
      AND luga.hk_group_id IN (
            SELECT hk_group_id
            FROM VT260725214E22__DWH.h_groups
            ORDER BY registration_dt
            LIMIT 10)
    GROUP BY luga.hk_group_id
)
,user_group_messages AS (
    SELECT lgd.hk_group_id,
           count(DISTINCT lum.hk_user_id) AS cnt_users_in_group_with_messages
    FROM VT260725214E22__DWH.l_groups_dialogs AS lgd
    LEFT JOIN VT260725214E22__DWH.l_user_message AS lum
           ON lgd.hk_message_id = lum.hk_message_id
    WHERE lgd.hk_group_id IN (
            SELECT hk_group_id
            FROM VT260725214E22__DWH.h_groups
            ORDER BY registration_dt
            LIMIT 10)
    GROUP BY lgd.hk_group_id
)
SELECT ugl.hk_group_id,
       ugl.cnt_added_users,
       ugm.cnt_users_in_group_with_messages,
       ugm.cnt_users_in_group_with_messages::numeric
           / ugl.cnt_added_users AS group_conversion
FROM user_group_log AS ugl
LEFT JOIN user_group_messages AS ugm ON ugl.hk_group_id = ugm.hk_group_id
ORDER BY group_conversion DESC;
