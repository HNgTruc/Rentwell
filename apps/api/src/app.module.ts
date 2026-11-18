import { randomUUID } from 'node:crypto';
import { Module } from '@nestjs/common';
import { LoggerModule } from 'nestjs-pino';
import { ConfigModule } from './config/config.module';
import { APP_CONFIG, AppConfig } from './config/env';
import { DatabaseModule } from './database/database.module';
import { HealthModule } from './modules/health/health.module';

@Module({
  imports: [
    ConfigModule,
    LoggerModule.forRootAsync({
      inject: [APP_CONFIG],
      useFactory: (cfg: AppConfig) => ({
        pinoHttp: {
          level: cfg.LOG_LEVEL,
          // request_id xuyên suốt: nhận từ proxy nếu có, không thì tự sinh; trả lại trong header
          genReqId: (req, res) => {
            const incoming = req.headers['x-request-id'];
            const id =
              typeof incoming === 'string' && /^[\w-]{8,64}$/.test(incoming) ? incoming : randomUUID();
            res.setHeader('x-request-id', id);
            return id;
          },
          // Mỗi dòng log của request có request_id ở cấp cao nhất (docs/01-architecture/system-architecture.md mục 8)
          customProps: (req) => ({ request_id: req.id }),
          // Chỉ ghi trường tối thiểu: KHÔNG ghi header, body, query (có thể chứa token, dữ liệu cá nhân)
          serializers: {
            req: (req: { method?: string; url?: string }) => ({
              method: req.method,
              path: req.url?.split('?')[0],
            }),
            res: (res: { statusCode?: number }) => ({ status: res.statusCode }),
          },
        },
      }),
    }),
    DatabaseModule,
    HealthModule,
  ],
})
export class AppModule {}
