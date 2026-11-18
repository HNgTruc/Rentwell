import { describe, expect, it } from 'vitest';
import { InvalidConfigError, parseEnv } from './env';

const validDb = 'postgres://rentwell_app:x@127.0.0.1:5432/rentwell';

describe('parseEnv', () => {
  it('nhận cấu hình tối thiểu và điền giá trị mặc định', () => {
    const cfg = parseEnv({ DATABASE_URL: validDb });
    expect(cfg).toMatchObject({
      NODE_ENV: 'development',
      PORT: 3000,
      LOG_LEVEL: 'info',
      DATABASE_POOL_MAX: 10,
    });
  });

  it('đổi PORT dạng chuỗi sang số', () => {
    expect(parseEnv({ DATABASE_URL: validDb, PORT: '4000' }).PORT).toBe(4000);
  });

  it.each([
    { name: 'thiếu DATABASE_URL', env: {} },
    { name: 'DATABASE_URL không phải postgres', env: { DATABASE_URL: 'mysql://a@b/c' } },
    { name: 'PORT ngoài khoảng', env: { DATABASE_URL: validDb, PORT: '70000' } },
    { name: 'NODE_ENV lạ', env: { DATABASE_URL: validDb, NODE_ENV: 'staging-x' } },
  ])('từ chối khi $name', ({ env }) => {
    expect(() => parseEnv(env)).toThrow(InvalidConfigError);
  });

  it('thông báo lỗi không chứa giá trị bí mật', () => {
    try {
      parseEnv({ DATABASE_URL: 'mysql://user:sieu-bi-mat@host/db' });
    } catch (e) {
      expect(String(e)).not.toContain('sieu-bi-mat');
    }
  });
});
