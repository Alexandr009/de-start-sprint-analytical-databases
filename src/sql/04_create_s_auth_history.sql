-- Шаг 6. Сателлит s_auth_history.
-- Хранит историю событий пользователя в группе.
-- Первичного ключа нет — как и положено сателлиту в Data Vault.
DROP TABLE IF EXISTS VT260725214E22__DWH.s_auth_history CASCADE;

CREATE TABLE VT260725214E22__DWH.s_auth_history
(
    hk_l_user_group_activity int NOT NULL
        CONSTRAINT fk_s_auth_history_l_user_group_activity
        REFERENCES VT260725214E22__DWH.l_user_group_activity (hk_l_user_group_activity),
    user_id_from int,          -- кто пригласил (пусто, если вступил сам)
    event        varchar(10),  -- create / add / leave
    event_dt     datetime,
    load_dt      datetime,
    load_src     varchar(20)
)
ORDER BY load_dt
SEGMENTED BY hk_l_user_group_activity ALL NODES
PARTITION BY load_dt::date
GROUP BY calendar_hierarchy_day(load_dt::date, 3, 2);
