import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { Logger } from 'nestjs-pino';
import { AppModule } from './app.module';
import { APP_CONFIG, AppConfig } from './config/env';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });
  app.useLogger(app.get(Logger));
  app.getHttpAdapter().getInstance().disable('x-powered-by');
  app.setGlobalPrefix('v1');
  app.enableShutdownHooks();

  const cfg = app.get<AppConfig>(APP_CONFIG);
  if (cfg.NODE_ENV !== 'production') {
    const doc = SwaggerModule.createDocument(
      app,
      new DocumentBuilder().setTitle('Rentwell API').setVersion('v1').addBearerAuth().build(),
    );
    SwaggerModule.setup('docs', app, doc);
  }

  await app.listen(cfg.PORT);
}

void bootstrap();
