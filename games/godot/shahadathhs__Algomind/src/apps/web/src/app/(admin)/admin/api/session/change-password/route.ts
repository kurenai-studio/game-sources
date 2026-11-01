import { changePassword } from "@/lib/admin/bff";

export const dynamic = "force-dynamic";

export function POST(req: Request): Promise<Response> {
  return changePassword(req);
}
