import swc from 'unplugin-swc';
import { defineConfig } from 'vitest/config';

// SWC biên dịch decorator và metadata của NestJS (esbuild mặc định của Vitest không làm được).
// Hai nhóm test:
//   unit        : src/**/*.spec.ts, không cần Docker (`pnpm test:unit`).
//   integration : test/**/*.spec.ts, Postgres thật qua Testcontainers (test/helpers/postgres.global-setup.ts).
// `pnpm test` chạy cả hai.
const plugins = [swc.vite({ module: { type: 'es6' } })];

export default defineConfig({
  test: {
    environment: 'node',
    projects: [
      { plugins, test: { name: 'unit', include: ['src/**/*.spec.ts'], environment: 'node' } },
      {
        plugins,
        test: {
          name: 'integration',
          include: ['test/**/*.spec.ts'],
          environment: 'node',
          globalSetup: ['test/helpers/postgres.global-setup.ts'],
          hookTimeout: 120_000, // lần đầu phải kéo image Postgres
          testTimeout: 30_000,
        },
      },
    ],
  },
});
