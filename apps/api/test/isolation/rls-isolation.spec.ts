import { Kysely, PostgresDialect, sql } from 'kysely';
import { Pool } from 'pg';
import { afterAll, beforeAll, describe, expect, inject, it } from 'vitest';
import type { Database } from '../../src/database/database.module';
import { withTenant } from '../../src/database/tenant-context';

// Spike P0 (ADR 0012): Kysely + RLS trên Postgres thật, bằng ROLE ỨNG DỤNG (rentwell_app).
// CSDL do Testcontainers dựng, đã migrate và seed (test/helpers/postgres.global-setup.ts, ADR 0014).
const url = inject('appDatabaseUrl');

const TENANT_A = 'a0000000-0000-4000-8000-000000000000'; // chuỗi A trong seed
const TENANT_B = 'b0000000-0000-4000-8000-000000000000'; // chuỗi B trong seed
const USER_OWNER_A = 'c0000000-0000-4000-8000-000000000001';

describe('RLS với Kysely (role ứng dụng)', () => {
  let db: Database;
  let single: Database; // pool 1 kết nối: buộc mọi giao dịch dùng lại cùng một kết nối

  const make = (max: number): Database =>
    new Kysely({ dialect: new PostgresDialect({ pool: new Pool({ connectionString: url, max }) }) });

  const tenantsOf = async (q: Database | Parameters<Parameters<typeof withTenant>[2]>[0]) =>
    (await q.selectFrom('memberships').select('tenant_id').execute()).map((r) => r.tenant_id as string);

  beforeAll(() => {
    db = make(4);
    single = make(1);
  });

  afterAll(async () => {
    await db.destroy();
    await single.destroy();
  });

  it('role ứng dụng không vượt được RLS', async () => {
    const { rows } = await sql<{ bypass: boolean }>`
      select rolsuper or rolbypassrls as bypass from pg_roles where rolname = current_user`.execute(db);
    expect(rows[0]?.bypass).toBe(false);
  });

  it('không có ngữ cảnh tenant thì không thấy dòng nào', async () => {
    expect(await tenantsOf(db)).toEqual([]);
  });

  it('chỉ thấy dữ liệu của tenant đang đặt', async () => {
    const a = await withTenant(db, TENANT_A, tenantsOf);
    const b = await withTenant(db, TENANT_B, tenantsOf);
    expect(a.length).toBeGreaterThan(0);
    expect(new Set(a)).toEqual(new Set([TENANT_A]));
    expect(b.length).toBeGreaterThan(0);
    expect(new Set(b)).toEqual(new Set([TENANT_B]));
  });

  it('ngữ cảnh không rò sang giao dịch sau trên cùng kết nối', async () => {
    await withTenant(single, TENANT_A, tenantsOf);
    const { rows } = await sql<{ t: string | null }>`
      select current_setting('app.tenant_id', true) as t`.execute(single);
    expect(rows[0]?.t ?? '').toBe('');
    expect(await tenantsOf(single)).toEqual([]);
  });

  it('ngữ cảnh không rò khi giao dịch lỗi và rollback', async () => {
    await expect(
      withTenant(single, TENANT_A, async () => {
        throw new Error('lỗi giữa chừng');
      }),
    ).rejects.toThrow('lỗi giữa chừng');
    expect(await tenantsOf(single)).toEqual([]);
  });

  it('nhiều request song song không lẫn tenant', async () => {
    const runs = Array.from({ length: 20 }, (_, i) => (i % 2 ? TENANT_B : TENANT_A));
    const results = await Promise.all(runs.map((t) => withTenant(db, t, tenantsOf)));
    results.forEach((rows, i) => expect(new Set(rows)).toEqual(new Set([runs[i]])));
  });

  it('không ghi được dòng của tenant khác (WITH CHECK)', async () => {
    await expect(
      withTenant(db, TENANT_A, (trx) =>
        trx
          .insertInto('memberships')
          .values({ tenant_id: TENANT_B, user_id: USER_OWNER_A, role: 'support' })
          .execute(),
      ),
    ).rejects.toMatchObject({ code: '42501' });
  });

  it('không sửa được dòng của tenant khác (bị lọc, 0 dòng)', async () => {
    const res = await withTenant(db, TENANT_A, (trx) =>
      trx
        .updateTable('memberships')
        .set({ role: 'support' })
        .where('tenant_id', '=', TENANT_B)
        .executeTakeFirst(),
    );
    expect(Number(res.numUpdatedRows)).toBe(0);
  });
});
