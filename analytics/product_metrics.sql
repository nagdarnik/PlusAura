-- PostgreSQL reference queries for an anonymized analytics export.
-- Standalone schema: does not modify the application's public tables.
CREATE SCHEMA IF NOT EXISTS plusaura_analytics;
CREATE TABLE IF NOT EXISTS plusaura_analytics.users (
    id text PRIMARY KEY,
    signup date NOT NULL,
    segment text NOT NULL
);
CREATE TABLE IF NOT EXISTS plusaura_analytics.sessions (
    id text PRIMARY KEY,
    user_id text NOT NULL REFERENCES plusaura_analytics.users(id),
    date date NOT NULL
);
CREATE TABLE IF NOT EXISTS plusaura_analytics.workouts (
    id text PRIMARY KEY,
    user_id text NOT NULL REFERENCES plusaura_analytics.users(id),
    date date NOT NULL,
    duration numeric NOT NULL CHECK (duration >= 0),
    completed boolean NOT NULL
);
CREATE INDEX IF NOT EXISTS sessions_user_date_idx
    ON plusaura_analytics.sessions(user_id, date);
CREATE INDEX IF NOT EXISTS workouts_user_date_idx
    ON plusaura_analytics.workouts(user_id, date);

-- 1. DAU and daily sessions. Replace dates; NULL means all segments.
-- MAU/WAU on any day retain history before the displayed period.
WITH params AS (
    SELECT DATE '2026-07-01' AS start_date, DATE '2026-09-30' AS end_date,
           NULL::text AS segment
), calendar AS (
    SELECT generate_series(start_date, end_date, '1 day')::date AS day FROM params
), activity AS (
    SELECT s.* FROM plusaura_analytics.sessions s
    JOIN plusaura_analytics.users u ON u.id = s.user_id
    CROSS JOIN params p
    WHERE s.date BETWEEN u.signup AND p.end_date
      AND (p.segment IS NULL OR u.segment = p.segment)
), daily AS (
    SELECT c.day, COUNT(a.id) AS sessions,
           COUNT(DISTINCT a.user_id) AS dau
    FROM calendar c LEFT JOIN activity a ON a.date = c.day
    GROUP BY c.day
)
SELECT d.*,
       AVG(d.dau) OVER (ORDER BY d.day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
           AS displayed_dau_moving_average,
       (SELECT COUNT(DISTINCT user_id) FROM activity
        WHERE date BETWEEN d.day - 6 AND d.day) AS wau,
       (SELECT COUNT(DISTINCT user_id) FROM activity
        WHERE date BETWEEN d.day - 29 AND d.day) AS mau
FROM daily d ORDER BY d.day;

-- 2. Exact-day D7/D30 retention; denominator = mature registrations only.
WITH params AS (
    SELECT DATE '2026-07-01' AS start_date, DATE '2026-09-30' AS as_of,
           NULL::text AS segment
), eligible AS (
    SELECT u.*, n.day FROM plusaura_analytics.users u
    CROSS JOIN params p CROSS JOIN (VALUES (7), (30)) n(day)
    WHERE u.signup BETWEEN p.start_date AND p.as_of
      AND u.signup + n.day <= p.as_of
      AND (p.segment IS NULL OR u.segment = p.segment)
), outcomes AS (
    SELECT e.*, EXISTS (
        SELECT 1 FROM plusaura_analytics.sessions s
        WHERE s.user_id = e.id AND s.date = e.signup + e.day
    ) AS returned FROM eligible e
)
SELECT day, COUNT(*) AS eligible_users,
       COUNT(*) FILTER (WHERE returned) AS retained_users,
       AVG(returned::int)::numeric AS retention
FROM outcomes GROUP BY day ORDER BY day;

-- 3. First-week workout groups versus exact-day D30 retention.
-- Descriptive association, not a randomized experiment or causal estimate.
WITH params AS (
    SELECT DATE '2026-07-01' AS start_date, DATE '2026-09-30' AS as_of,
           NULL::text AS segment
), mature AS (
    SELECT u.* FROM plusaura_analytics.users u CROSS JOIN params p
    WHERE u.signup BETWEEN p.start_date AND p.as_of - 30
      AND (p.segment IS NULL OR u.segment = p.segment)
), first_week AS (
    SELECT u.id, u.signup, COUNT(w.id) AS completed_workouts
    FROM mature u LEFT JOIN plusaura_analytics.workouts w
      ON w.user_id = u.id AND w.completed
      AND w.date BETWEEN u.signup AND u.signup + 6
    GROUP BY u.id, u.signup
), outcomes AS (
    SELECT f.*, EXISTS (
        SELECT 1 FROM plusaura_analytics.sessions s
        WHERE s.user_id = f.id AND s.date = f.signup + 30
    ) AS returned FROM first_week f
)
SELECT CASE WHEN completed_workouts >= 3 THEN '3+' ELSE '0-2' END AS workout_group,
       COUNT(*) AS eligible_users,
       COUNT(*) FILTER (WHERE returned) AS retained_users,
       AVG(returned::int)::numeric AS d30_retention
FROM outcomes GROUP BY 1 ORDER BY 1;
