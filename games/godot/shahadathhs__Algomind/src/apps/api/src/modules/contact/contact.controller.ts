import { Body, Controller, Get, Put, Req, UseGuards } from "@nestjs/common";
import { ApiBearerAuth, ApiOperation, ApiTags } from "@nestjs/swagger";
import { AdminRoute } from "../../core/http/api-docs.js";
import { parseInput } from "../../core/http/errors.js";
import { AdminGuard, JwtAuthGuard } from "../auth/auth.module.js";
import type { AuthenticatedRequest } from "../auth/auth.types.js";
import { contactInputSchema, type AdminContactView, type ContactView } from "./contact.schemas.js";
import { ContactService } from "./contact.service.js";

@ApiTags("contact")
@Controller("contact")
export class ContactController {
  constructor(private readonly contact: ContactService) {}

  @Get()
  @ApiOperation({
    summary: "How to reach the developer, for the public contact page.",
    description: "An empty field is not shown. The details are edited in the dashboard.",
  })
  get(): Promise<ContactView> {
    return this.contact.get();
  }
}

@ApiTags("admin: contact")
@ApiBearerAuth()
@Controller("admin/contact")
@UseGuards(JwtAuthGuard, AdminGuard)
@AdminRoute()
export class AdminContactController {
  constructor(private readonly contact: ContactService) {}

  @Get()
  @ApiOperation({ summary: "The contact details with when and by whom they last changed." })
  get(): Promise<AdminContactView> {
    return this.contact.getAdmin();
  }

  @Put()
  @ApiOperation({
    summary: "Replace the contact details shown on the public contact page.",
    description: "An empty email, link or text hides that line. Links must be https.",
  })
  update(@Body() body: unknown, @Req() req: AuthenticatedRequest): Promise<AdminContactView> {
    return this.contact.update(parseInput(contactInputSchema, body), req.user.id);
  }
}
