-- Шаг 2. Создание таблицы group_log в staging-слое.
-- Структура повторяет формат файла /data/group_log.csv.

DROP TABLE IF EXISTS VT260725214E22__STAGING.group_log CASCADE;

CREATE TABLE VT260725214E22__STAGING.group_log
(
    group_id     int,
    user_id      int,
    user_id_from int,          -- пустое, если пользователь вступил сам
    event        varchar(10),  -- create / add / leave
    datetime     timestamp
)
ORDER BY group_id, user_id
SEGMENTED BY hash(group_id, user_id) ALL NODES
PARTITION BY datetime::date
GROUP BY calendar_hierarchy_day(datetime::date, 3, 2);
