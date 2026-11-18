import { Controller, Get, HttpStatus, Res } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { HealthService, HealthStatus } from './health.service';

// Chỉ cần đặt mã trạng thái; tránh phụ thuộc kiểu của express.
type StatusSettable = { status(code: number): unknown };

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(private readonly health: HealthService) {}

  @Get()
  @ApiOperation({ summary: 'Kiểm tra API và kết nối CSDL (200 khi ổn, 503 khi CSDL không phản hồi)' })
  async get(@Res({ passthrough: true }) res: StatusSettable): Promise<{ data: HealthStatus }> {
    const result = await this.health.check();
    res.status(result.status === 'ok' ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE);
    return { data: result };
  }
}
