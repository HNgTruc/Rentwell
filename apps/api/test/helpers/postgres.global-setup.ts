import { execFileSync } from 'node:child_process';
import { createRequire } from 'node:module';
import path from 'node:path';
import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import type { TestProject } from 'vitest/node';

// Global setup của nhóm test `integration` (ADR 0014): bật một Postgres tạm bằng Testcontainers,
// dựng giống hệt môi trường dev rồi đưa URL role ứng dụng cho test qua `inject('appDatabaseUrl')`.
//   1. Tạo role bằng chính infra/compose/postgres-init/*.sql (chạy lúc initdb).
//   2. Chạy migration bằng dbmate với role migrator, như `pnpm db:migrate`.
//   3. Nạp seed bằng superuser, như `pnpm db:seed`.
// Không đụng Postgres dev. Cần Docker.

declare module 'vitest' {
  export interface ProvidedContext {
    appDatabaseUrl: string;
  }
}

const repoRoot = path.resolve(__dirname, '../../../..'); // api là CommonJS: dùng __dirname, không import.meta
const IMAGE = 'postgres:16.16'; // cùng image với infra/compose/docker-compose.dev.yml

// Mật khẩu role khớp infra/compose/postgres-init/01-roles.sql (giá trị giả của dev/CI).
const MIGRATOR = 'rentwell_migrator:migrator_dev';
const APP = 'rentwell_app:app_dev';

let container: StartedPostgreSqlContainer | undefined;

function runDbmate(migrationUrl: string): void {
  // dbmate là devDependency của workspace/; gọi thẳng cli.js bằng Node để chạy được cả Windows lẫn Linux.
  const requireFromWorkspace = createRequire(path.join(repoRoot, 'workspace', 'package.json'));
  const cli = path.join(path.dirname(requireFromWorkspace.resolve('dbmate/package.json')), 'dist', 'cli.js');
  execFileSync(
    process.execPath,
    [
      cli,
      '--url',
      migrationUrl,
      '--migrations-dir',
      path.join(repoRoot, 'db', 'migrations'),
      '--no-dump-schema',
      'up',
    ],
    { stdio: 'pipe' },
  );
}

export async function setup(project: TestProject): Promise<void> {
  container = await new PostgreSqlContainer(IMAGE)
    .withDatabase('rentwell')
    .withUsername('postgres')
    .withPassword('postgres_test')
    .withEnvironment({ TZ: 'Asia/Ho_Chi_Minh', PGTZ: 'Asia/Ho_Chi_Minh' })
    .withCommand(['postgres', '-c', 'timezone=Asia/Ho_Chi_Minh'])
    .withCopyDirectoriesToContainer([
      {
        source: path.join(repoRoot, 'infra', 'compose', 'postgres-init'),
        target: '/docker-entrypoint-initdb.d',
      },
      { source: path.join(repoRoot, 'db'), target: '/db' },
    ])
    .start();

  const hostPort = `${container.getHost()}:${container.getPort()}`;
  const url = (cred: string) => `postgres://${cred}@${hostPort}/rentwell?sslmode=disable`;

  runDbmate(url(MIGRATOR));

  const seed = await container.exec([
    'psql',
    '-U',
    'postgres',
    '-d',
    'rentwell',
    '-v',
    'ON_ERROR_STOP=1',
    '-q',
    '-f',
    '/db/seeds/001_dev_seed.sql',
  ]);
  if (seed.exitCode !== 0) throw new Error(`Nạp seed thất bại:\n${seed.output}`);

  project.provide('appDatabaseUrl', url(APP));
}

export async function teardown(): Promise<void> {
  await container?.stop();
}
