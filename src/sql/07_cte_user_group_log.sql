-- Шаг 7.2. CTE user_group_log.
-- Считает, сколько УНИКАЛЬНЫХ пользователей вступили (event = 'add')
-- в каждую из 10 самых старых групп (самые ранние registration_dt в h_groups).

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
SELECT hk_group_id,
       cnt_added_users
FROM user_group_log
ORDER BY cnt_added_users
LIMIT 10;
