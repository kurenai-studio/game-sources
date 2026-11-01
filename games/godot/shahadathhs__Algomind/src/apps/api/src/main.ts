import "reflect-metadata";
import { Logger } from "@nestjs/common";
import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module.js";
import { setupApp, setupDocs } from "./app.setup.js";
import { AppConfig } from "./core/config/app-config.js";

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);
  setupApp(app);
  setupDocs(app);
  const { port } = app.get(AppConfig);
  await app.listen(port, "0.0.0.0");
  new Logger("Bootstrap").log(`API listening on port ${port} (docs at /docs)`);
}

void bootstrap();
