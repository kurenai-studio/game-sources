import { proxy } from "@/lib/admin/bff";

export const dynamic = "force-dynamic";

type Context = { params: Promise<{ path: string[] }> };

async function handle(req: Request, ctx: Context): Promise<Response> {
  const { path } = await ctx.params;
  return proxy(req, path);
}

export { handle as GET, handle as POST, handle as PUT, handle as PATCH, handle as DELETE };
