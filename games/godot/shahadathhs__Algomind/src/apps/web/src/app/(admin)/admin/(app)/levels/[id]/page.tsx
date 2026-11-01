import { LevelEditor } from "@/components/admin/level-editor";

export default async function LevelPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <LevelEditor levelId={id} />;
}
