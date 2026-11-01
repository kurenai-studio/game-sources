import { Body, Controller, Get, HttpCode, Param, Patch, Post, UseGuards } from "@nestjs/common";
import { ApiOperation, ApiTags } from "@nestjs/swagger";
import { AdminRoute, BodyOf, ErrorOf, ResponseOf } from "../../core/http/api-docs.js";
import { parseInput } from "../../core/http/errors.js";
import { AdminGuard, JwtAuthGuard } from "../auth/auth.module.js";
import {
  clientVersionListSchema,
  clientVersionSchema,
  createClientVersionSchema,
  updateClientVersionSchema,
  type ClientVersionView,
} from "./client-versions.schemas.js";
import { ClientVersionsService } from "./client-versions.service.js";

@ApiTags("admin: client versions")
@Controller("admin/client-versions")
@UseGuards(JwtAuthGuard, AdminGuard)
@AdminRoute()
export class ClientVersionsController {
  constructor(private readonly versions: ClientVersionsService) {}

  @Get()
  @ApiOperation({
    summary: "The capabilities registry: app versions and the mechanics they support.",
  })
  @ResponseOf(200, clientVersionListSchema, "All registered versions, newest release first.")
  list(): Promise<{ items: ClientVersionView[] }> {
    return this.versions.list();
  }

  @Post()
  @HttpCode(201)
  @ApiOperation({ summary: "Register an app version." })
  @BodyOf(createClientVersionSchema)
  @ResponseOf(201, clientVersionSchema, "The new registry row.")
  @ErrorOf(409, "VERSION_EXISTS: the version is already registered.")
  @ErrorOf(422, "VALIDATION_FAILED.")
  create(@Body() body: unknown): Promise<ClientVersionView> {
    return this.versions.create(parseInput(createClientVersionSchema, body));
  }

  @Patch(":id")
  @ApiOperation({
    summary: "Change the supported mechanics, release date, or the minimum flag.",
    description:
      "isMinimum can only be set to true, which moves the flag from the previous minimum.",
  })
  @BodyOf(updateClientVersionSchema)
  @ResponseOf(200, clientVersionSchema, "The updated registry row.")
  @ErrorOf(404, "NOT_FOUND.")
  @ErrorOf(422, "VALIDATION_FAILED.")
  update(@Param("id") id: string, @Body() body: unknown): Promise<ClientVersionView> {
    return this.versions.update(id, parseInput(updateClientVersionSchema, body));
  }
}
