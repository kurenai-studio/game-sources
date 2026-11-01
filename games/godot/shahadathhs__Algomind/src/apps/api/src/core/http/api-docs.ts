import { applyDecorators } from "@nestjs/common";
import { ApiBearerAuth, ApiBody, ApiQuery, ApiResponse } from "@nestjs/swagger";
import { z } from "zod";

type SchemaObject = Record<string, unknown>;

/** The OpenAPI 3.0 schema of a zod schema, so the documentation is generated from the validator. */
export function openApiSchema(schema: z.ZodType, io: "input" | "output" = "output"): SchemaObject {
  const { $schema: _ignored, ...rest } = z.toJSONSchema(schema, {
    target: "openapi-3.0",
    io,
    unrepresentable: "any",
  }) as SchemaObject;
  return rest;
}

/** Documents a JSON request body. */
export const BodyOf = (schema: z.ZodType) =>
  ApiBody({ schema: openApiSchema(schema, "input"), required: true });

/** Documents a response with a concrete schema. */
export const ResponseOf = (status: number, schema: z.ZodType | null, description: string) =>
  schema
    ? ApiResponse({ status, description, schema: openApiSchema(schema) })
    : ApiResponse({ status, description });

/** Documents each key of a zod object as a query parameter. */
export function QueryOf(schema: z.ZodObject) {
  const json = openApiSchema(schema, "input");
  const properties = (json.properties ?? {}) as Record<string, SchemaObject>;
  const required = new Set((json.required ?? []) as string[]);
  return applyDecorators(
    ...Object.entries(properties).map(([name, property]) =>
      ApiQuery({ name, required: required.has(name), schema: property }),
    ),
  );
}

const errorBody = z.object({
  statusCode: z.number().int(),
  code: z.string(),
  message: z.string(),
  issues: z.array(z.object({ path: z.string(), code: z.string(), message: z.string() })).optional(),
});

/** Bearer authentication and the 401 and 403 answers every admin route can give. */
export const AdminRoute = () =>
  applyDecorators(
    ApiBearerAuth(),
    ResponseOf(401, errorBody, "Missing, invalid, or expired access token."),
    ResponseOf(
      403,
      errorBody,
      "Not an admin, or the password must be changed first (code PASSWORD_CHANGE_REQUIRED).",
    ),
  );

/** Documents an error status with the standard error body. */
export const ErrorOf = (status: number, description: string) =>
  ResponseOf(status, errorBody, description);
