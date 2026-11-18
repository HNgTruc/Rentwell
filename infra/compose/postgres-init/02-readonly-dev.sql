-- CHỈ DÙNG CHO DEV. Không bao giờ tạo role này ở staging hay production.
-- rentwell_readonly: cho MCP Postgres (Claude Code) xem lược đồ và dữ liệu seed.
--   Chỉ SELECT, có BYPASSRLS (role chỉ đọc theo RLS sẽ thấy 0 dòng ở bảng nghiệp vụ vì không đặt app.tenant_id).
--   Không ghi được gì: không có INSERT/UPDATE/DELETE, mặc định giao dịch chỉ đọc.
-- Chạy tự động khi tạo volume mới; chạy lại an toàn trên volume đã có:
--   docker compose -f infra/compose/docker-compose.dev.yml exec -T postgres psql -U postgres -d rentwell -f /docker-entrypoint-initdb.d/02-readonly-dev.sql

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rentwell_readonly') THEN
    CREATE ROLE rentwell_readonly LOGIN PASSWORD 'readonly_dev'
      NOSUPERUSER NOCREATEROLE NOCREATEDB BYPASSRLS;
  END IF;
END $$;

ALTER ROLE rentwell_readonly SET default_transaction_read_only = on;

\connect rentwell
GRANT CONNECT ON DATABASE rentwell TO rentwell_readonly;
GRANT USAGE ON SCHEMA public TO rentwell_readonly;
-- Bảng đã có (volume đã migrate) và bảng migrator tạo về sau.
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rentwell_readonly;
ALTER DEFAULT PRIVILEGES FOR ROLE rentwell_migrator IN SCHEMA public
  GRANT SELECT ON TABLES TO rentwell_readonly;
