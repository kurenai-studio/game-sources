import { Controller, Get, Query, UseGuards } from "@nestjs/common";
import { ApiOperation, ApiTags } from "@nestjs/swagger";
import { AdminRoute, QueryOf, ResponseOf } from "../../core/http/api-docs.js";
import { parseInput } from "../../core/http/errors.js";
import { AdminGuard, JwtAuthGuard } from "../auth/auth.module.js";
import { AuditService } from "./audit.service.js";
import { auditListQuerySchema, auditPageSchema, type AuditPage } from "./audit.schemas.js";

@ApiTags("admin: audit")
@Controller("admin/audit")
@UseGuards(JwtAuthGuard, AdminGuard)
@AdminRoute()
export class AuditController {
  constructor(private readonly audit: AuditService) {}

  @Get()
  @ApiOperation({ summary: "The audit log, newest first, optionally filtered by action." })
  @QueryOf(auditListQuerySchema)
  @ResponseOf(200, auditPageSchema, "One page of audit events.")
  list(@Query() query: unknown): Promise<AuditPage> {
    return this.audit.list(parseInput(auditListQuerySchema, query));
  }
}
