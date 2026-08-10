# Проект спринта "Аналитические базы данных"

### Описание
Репозиторий предназначен для сдачи проекта српинта "Аналитические базы данных"

### Как работать с репозиторием
1. В вашем GitHub-аккаунте автоматически создастся репозиторий `de-start-sprint-analytical-databases` после того, как вы привяжете свой GitHub-аккаунт на Платформе.
2. Скопируйте репозиторий на свой локальный компьютер, в качестве пароля укажите ваш `Access Token` (получить нужно на странице [Personal Access Tokens](https://github.com/settings/tokens)):
	* `git clone https://github.com/{{ username }}/de-start-sprint-analytical-databases.git`
3. Перейдите в директорию с проектом: 
	* `cd de-start-sprint-analytical-databases`
4. Выполните проект и сохраните получившийся код в локальном репозитории:
	* `git add .`
	* `git commit -m 'my best commit'`
5. Обновите репозиторий в вашем GutHub-аккаунте:
	* `git push origin main`

### Структура репозитория
- `/src/dags`
- `/src/sql`

---

## Решение проекта

Схемы в Vertica: `VT260725214E22__STAGING` (staging-слой) и `VT260725214E22__DWH` (слой DDS, модель Data Vault).

### Состав решения

| Файл | Шаг проекта | Назначение |
| --- | --- | --- |
| `src/dags/project_get_group_log.py` | 1 | DAG: выгружает `group_log.csv` из бакета `sprint6` в папку `/data` |
| `src/sql/01_create_staging_group_log.sql` | 2 | Создание таблицы `STAGING.group_log` |
| `src/dags/project_load_group_log.py` | 3 | DAG: читает `/data/group_log.csv` и грузит в `STAGING.group_log` |
| `src/sql/02_create_l_user_group_activity.sql` | 4 | Создание линка `DWH.l_user_group_activity` |
| `src/sql/03_migrate_l_user_group_activity.sql` | 5 | Миграция данных в линк |
| `src/sql/04_create_s_auth_history.sql` | 6 | Создание сателлита `DWH.s_auth_history` |
| `src/sql/05_migrate_s_auth_history.sql` | 6 | Наполнение сателлита |
| `src/sql/06_cte_user_group_messages.sql` | 7.1 | CTE `user_group_messages` |
| `src/sql/07_cte_user_group_log.sql` | 7.2 | CTE `user_group_log` |
| `src/sql/08_group_conversion.sql` | 7.3 | Итоговый запрос: конверсия в первое сообщение |

### Переменные окружения

Секреты не хранятся в репозитории — DAG'и читают их из окружения. Перед запуском задайте:

```
# доступ к S3 (Yandex Object Storage)
AWS_ACCESS_KEY_ID=<ключ курса>
AWS_SECRET_ACCESS_KEY=<секрет курса>

# подключение к Vertica
VERTICA_HOST=vertica.data-engineer.education-services.ru
VERTICA_PORT=5433
VERTICA_USER=<логин>
VERTICA_PASSWORD=<пароль>
VERTICA_DB=dwh
VERTICA_STAGING_SCHEMA=<логин в верхнем регистре>__STAGING
```

### Порядок выполнения

Скрипты запускаются строго в порядке нумерации — он определён зависимостями по внешним ключам:

1. DAG `project_get_group_log` — файл появляется в `/data`.
2. `01_create_staging_group_log.sql` — создаём приёмник в staging.
3. DAG `project_load_group_log` — наполняем `STAGING.group_log`.
4. `02_create_l_user_group_activity.sql` — линк ссылается на **уже существующие** хабы `h_users` и `h_groups`.
5. `03_migrate_l_user_group_activity.sql` — наполняем линк.
6. `04_create_s_auth_history.sql` — сателлит ссылается на линк, поэтому создаётся после него.
7. `05_migrate_s_auth_history.sql` — наполняем сателлит; строки линка к этому моменту должны существовать.
8. `06`–`08` — аналитические запросы поверх заполненной модели.

### Модель данных

Новые объекты достраивают существующую модель Data Vault:

- **Линк `l_user_group_activity`** — связь «пользователь ↔ группа». Заполняется через `SELECT DISTINCT`: на одну пару приходится несколько событий в логе (вступил, вышел, вступил снова), но связь в линке хранится один раз.
- **Сателлит `s_auth_history`** — история событий этой связи (`create` / `add` / `leave`), а также `user_id_from` — кто пригласил пользователя в группу.

### Результат: конверсия по 10 самым старым группам

| hk_group_id | cnt_added_users | cnt_users_in_group_with_messages | group_conversion |
| --- | --- | --- | --- |
| 7174329635764732197 | 4794 | 2760 | 0.5757 |
| 206904954090724337 | 4311 | 2450 | 0.5683 |
| 4350425024258480878 | 4172 | 2363 | 0.5664 |
| 3214410852649090659 | 3781 | 2126 | 0.5623 |
| 5568963519328366880 | 4298 | 2387 | 0.5554 |
| 2461736748292367987 | 3575 | 1968 | 0.5505 |
| 9183043445192227260 | 3725 | 2046 | 0.5493 |
| 6014017525933240454 | 3405 | 1779 | 0.5225 |
| 7757992142189260835 | 2505 | 1138 | 0.4543 |
| 7279971728630971062 | 1914 | 861 | 0.4498 |

**Вывод для маркетинга:** рекламу стоит размещать в топ-5 групп с конверсией 55–58% — там больше половины вступивших начинают писать. Размер группы конверсию не определяет: самая крупная по числу вступивших не является лидером по конверсии, а группа с наименьшим числом участников оказалась в конце списка.

### Как запустить контейнер
Запустите локально команду:
```
docker run \
-d \
-p 3000:3000 \
-p 3002:3002 \
-p 15432:5432 \
--mount src=airflow_sp5,target=/opt/airflow \
--mount src=lesson_sp5,target=/lessons \
--mount src=db_sp5,target=/var/lib/postgresql/data \
--name=de-project-adb-server-local \
cr.yandex/crp1r8pht0n0gl25aug1/de-pg-cr-af:latest
```

После того как запустится контейнер, вам будут доступны:
- Airflow
	- `localhost:3000/airflow`
- БД
	- `jovyan:jovyan@localhost:15432/de`
