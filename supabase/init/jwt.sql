-- 复制自官方 supabase/supabase/docker/volumes/db/jwt.sql
-- 用 JWT_SECRET / JWT_EXP 初始化数据库设置（供 extensions 等使用）
\set jwt_secret `echo "$JWT_SECRET"`
\set jwt_exp `echo "$JWT_EXP"`

ALTER DATABASE postgres SET "app.settings.jwt_secret" TO :'jwt_secret';
ALTER DATABASE postgres SET "app.settings.jwt_exp" TO :'jwt_exp';