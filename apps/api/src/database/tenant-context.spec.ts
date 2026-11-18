import { describe, expect, it } from 'vitest';
import { assertTenantId, InvalidTenantIdError } from './tenant-context';

describe('assertTenantId', () => {
  it.each([
    ['UUID hợp lệ', 'a0000000-0000-4000-8000-000000000000', true],
    ['chuỗi rỗng', '', false],
    ['không phải UUID', 'tenant-a', false],
    ['chèn SQL', "a0000000-0000-4000-8000-000000000000'; drop table tenants; --", false],
  ])('%s', (_name, input, ok) => {
    if (ok) expect(assertTenantId(input)).toBe(input);
    else expect(() => assertTenantId(input)).toThrow(InvalidTenantIdError);
  });
});
