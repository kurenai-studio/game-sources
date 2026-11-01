import type { INestApplication } from "@nestjs/common";
import type { NestExpressApplication } from "@nestjs/platform-express";
import { DocumentBuilder, SwaggerModule } from "@nestjs/swagger";
import { AppConfig } from "./core/config/app-config.js";
import { HttpExceptionFilter } from "./core/errors/http-exception.filter.js";

/** Application-wide setup, kept separate from main.ts so it can be reused. */
export function setupApp(app: INestApplication): void {
  const config = app.get(AppConfig);
  // Behind a reverse proxy (Render), req.ip is the real client only when the proxy count is set.
  (app as NestExpressApplication).set("trust proxy", config.trustProxy);
  // Every JSON body is small (a level is a few kB, a full campaign order a few tens); reject
  // anything larger before it is parsed.
  (app as NestExpressApplication).useBodyParser("json", { limit: "64kb" });
  // Cheap response headers every JSON API should send. HSTS only where HTTPS is certain.
  (app as NestExpressApplication).use(
    (_req: unknown, res: { setHeader(name: string, value: string): void }, next: () => void) => {
      res.setHeader("X-Content-Type-Options", "nosniff");
      res.setHeader("Referrer-Policy", "no-referrer");
      res.setHeader("Cross-Origin-Resource-Policy", "same-site");
      if (config.nodeEnv === "production") {
        res.setHeader("Strict-Transport-Security", "max-age=15552000; includeSubDomains");
      }
      next();
    },
  );
  // Admin, auth, and account responses are per user and never cached.
  (app as NestExpressApplication).use(
    ["/v1/admin", "/v1/auth", "/v1/me"],
    (_req: unknown, res: { setHeader(name: string, value: string): void }, next: () => void) => {
      res.setHeader("Cache-Control", "no-store");
      next();
    },
  );
  app.setGlobalPrefix("v1");
  app.useGlobalFilters(new HttpExceptionFilter());
  app.enableCors({ origin: config.corsOrigins });
  app.enableShutdownHooks();
}

export function setupDocs(app: INestApplication): void {
  const document = SwaggerModule.createDocument(
    app,
    new DocumentBuilder()
      .setTitle("Algomind API")
      .setDescription("Authentication, levels, campaign, and publishing.")
      .setVersion("0.0.1")
      .addBearerAuth()
      .build(),
  );
  SwaggerModule.setup("docs", app, document);
}
