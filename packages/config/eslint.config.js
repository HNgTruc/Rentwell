// Cấu hình ESLint dùng chung (flat config). Mỗi package: `export { default } from '@rentwell/config/eslint'`
// hoặc nối thêm quy tắc riêng.
import tseslint from 'typescript-eslint';

export default tseslint.config(
  {
    ignores: ['dist/**', '.next/**', '.turbo/**', '.expo/**', 'coverage/**', 'node_modules/**', 'openapi/**'],
  },
  ...tseslint.configs.recommended,
  {
    rules: {
      // Tiền là số nguyên đồng: cấm parseFloat/toFixed trong mã (quy tắc pricing-money)
      'no-restricted-properties': [
        'error',
        { property: 'toFixed', message: 'Tiền là số nguyên đồng; không dùng toFixed.' },
      ],
      'no-restricted-globals': [
        'error',
        { name: 'parseFloat', message: 'Tiền là số nguyên đồng; không dùng parseFloat.' },
      ],
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_', varsIgnorePattern: '^_' }],
    },
  },
);
