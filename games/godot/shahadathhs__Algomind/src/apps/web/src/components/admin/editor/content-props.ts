import type { LevelContent } from "@/lib/admin/admin-api";

export type ContentProps = { content: LevelContent; onChange: (next: LevelContent) => void };
