import swc from 'unplugin-swc';
import { defineConfig } from 'vitest/config';

// SWC biên dịch decorator và metadata của NestJS (esbuild mặc định của Vitest không làm được).
export default defineConfig({
  plugins: [swc.vite({ module: { type: 'es6' } })],
  test: {
    include: ['src/**/*.spec.ts', 'test/**/*.spec.ts'],
    environment: 'node',
  },
});
