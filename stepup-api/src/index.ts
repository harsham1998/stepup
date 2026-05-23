import 'dotenv/config';
import { createApp } from './app';
import { logger } from './lib/logger';

const PORT = Number(process.env.PORT ?? 3000);
const app = createApp();

app.listen(PORT, () => {
  logger.info({ port: PORT }, 'StepUp API started');
});
