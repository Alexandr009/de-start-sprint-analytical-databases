-- Шаг 4. Таблица связей l_user_group_activity в слое DWH.
-- Связывает хабы h_users и h_groups: факт активности пользователя в группе.
DROP TABLE IF EXISTS VT260725214E22__DWH.l_user_group_activity CASCADE;

CREATE TABLE VT260725214E22__DWH.l_user_group_activity
(
    hk_l_user_group_activity int PRIMARY KEY,
    hk_user_id  int NOT NULL CONSTRAINT fk_l_user_group_activity_user
                 REFERENCES VT260725214E22__DWH.h_users (hk_user_id),
    hk_group_id int NOT NULL CONSTRAINT fk_l_user_group_activity_group
                 REFERENCES VT260725214E22__DWH.h_groups (hk_group_id),
    load_dt  datetime,
    load_src varchar(20)
)
ORDER BY load_dt
SEGMENTED BY hk_l_user_group_activity ALL NODES
PARTITION BY load_dt::date
GROUP BY calendar_hierarchy_day(load_dt::date, 3, 2);
