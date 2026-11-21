import { sql, Transaction } from 'kysely';
import { z } from 'zod';
import type { Database } from './database.module';
import type { DB as Schema } from './db.generated';

// Mọi truy vấn nghiệp vụ đi qua đây (CLAUDE.md quy tắc 2, ADR 0012).
// `set_config(..., true)` tương đương `SET LOCAL`: giá trị chỉ sống trong giao dịch hiện tại,
// tự mất khi COMMIT/ROLLBACK, nên không rò sang request khác dùng lại kết nối trong pool.
// Dùng `set_config` thay `SET LOCAL` vì `SET` không nhận tham số (`$1`), còn `set_config` thì có.

export type TenantTransaction = Transaction<Schema>;

export class InvalidTenantIdError extends Error {}

const tenantIdSchema = z.string().uuid();

/** Hàm thuần: kiểm `tenantId` là UUID trước khi chạm CSDL. */
export function assertTenantId(tenantId: string): string {
  const result = tenantIdSchema.safeParse(tenantId);
  if (!result.success) throw new InvalidTenantIdError('tenant_id không hợp lệ');
  return result.data;
}

/**
 * Mở giao dịch, đặt `app.tenant_id` cho riêng giao dịch đó, chạy `fn`.
 * `tenantId` phải lấy từ token và membership ở phía server, không bao giờ từ body/query của client.
 */
export async function withTenant<T>(
  db: Database,
  tenantId: string,
  fn: (trx: TenantTransaction) => Promise<T>,
): Promise<T> {
  const id = assertTenantId(tenantId);
  return db.transaction().execute(async (trx) => {
    await sql`select set_config('app.tenant_id', ${id}, true)`.execute(trx);
    return fn(trx);
  });
}
