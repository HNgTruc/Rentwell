import nextVitals from 'eslint-config-next/core-web-vitals';
import shared from '@rentwell/config/eslint';

const config = [...nextVitals, ...shared, { ignores: ['next-env.d.ts'] }];

export default config;
