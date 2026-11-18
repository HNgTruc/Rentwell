-- Chạy MỘT lần khi volume Postgres dev được tạo (docker-entrypoint-initdb.d), bằng superuser.
-- Hai role tách biệt (docs/05-devops/environments.md, quy tắc 9 trong CLAUDE.md):
--   rentwell_migrator : chủ sở hữu bảng, chạy migration. Không superuser.
--   rentwell_app      : role ứng dụng. Không superuser, không chủ bảng, không BYPASSRLS => RLS có hiệu lực.
-- Mật khẩu là giá trị giả cho dev; môi trường thật đặt qua kho bí mật.

CREATE ROLE rentwell_migrator LOGIN PASSWORD 'migrator_dev' NOSUPERUSER NOCREATEROLE NOCREATEDB NOBYPASSRLS;
CREATE ROLE rentwell_app      LOGIN PASSWORD 'app_dev'      NOSUPERUSER NOCREATEROLE NOCREATEDB NOBYPASSRLS;

ALTER DATABASE rentwell OWNER TO rentwell_migrator;
\connect rentwell
ALTER SCHEMA public OWNER TO rentwell_migrator;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO rentwell_app;

-- Mọi bảng, sequence, hàm do migrator tạo về sau: role ứng dụng được dùng (không được đổi cấu trúc).
ALTER DEFAULT PRIVILEGES FOR ROLE rentwell_migrator IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO rentwell_app;
ALTER DEFAULT PRIVILEGES FOR ROLE rentwell_migrator IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO rentwell_app;
ALTER DEFAULT PRIVILEGES FOR ROLE rentwell_migrator IN SCHEMA public
  GRANT EXECUTE ON FUNCTIONS TO rentwell_app;
