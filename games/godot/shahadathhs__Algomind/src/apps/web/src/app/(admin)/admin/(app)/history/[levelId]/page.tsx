import { LevelHistory } from "@/components/admin/level-history";

export default async function HistoryPage({ params }: { params: Promise<{ levelId: string }> }) {
  const { levelId } = await params;
  return <LevelHistory levelId={levelId} />;
}
