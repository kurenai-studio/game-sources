import { PublishReview } from "@/components/admin/publish-review";

export default async function PublishPage({ params }: { params: Promise<{ levelId: string }> }) {
  const { levelId } = await params;
  return <PublishReview levelId={levelId} />;
}
