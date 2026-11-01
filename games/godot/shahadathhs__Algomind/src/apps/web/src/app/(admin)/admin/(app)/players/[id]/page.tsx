import { PlayerDetail } from "@/components/admin/player-detail";

export default async function PlayerPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <PlayerDetail playerId={id} />;
}
