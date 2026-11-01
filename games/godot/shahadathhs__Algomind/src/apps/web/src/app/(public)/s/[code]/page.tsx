import type { Metadata } from "next";
import { connection } from "next/server";
import { ShareCard } from "@/components/public/share-card";
import { ShareNotice } from "@/components/public/share-notice";
import { Container } from "@/components/ui/container";
import { pageMetadata } from "@/lib/seo";
import { getShare, getShareBoard, resultText, shareCaption } from "@/lib/share";

type Props = { params: Promise<{ code: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { code } = await params;
  const state = await getShare(code);
  const path = `/s/${encodeURIComponent(code)}`;
  const base =
    state.status === "found"
      ? pageMetadata({
          title: state.share.title,
          shareTitle: `${state.share.title} on Algomind`,
          description: `${shareCaption(state.share)}: ${resultText(state.share)}.`,
          path,
        })
      : pageMetadata({
          title: "Shared result",
          description: "A result shared from Algomind, a programming puzzle for Android.",
          path,
        });
  return { ...base, robots: { index: false, follow: false } };
}

// Rendered per request, so a build made while the API is down never bakes in an error. The result
// is read with a one-minute cache. There is no client code: the page works with JavaScript off.
export default async function SharePage({ params }: Props) {
  await connection();
  const { code } = await params;
  const state = await getShare(code);
  // A missing code is a notice rendered here, not notFound(): the framework's 404 page is streamed
  // into a hidden element and shows only with JavaScript, and this page must work without it.
  if (state.status === "missing") {
    return (
      <ShareNotice
        title="Result not found."
        text="This link does not match a shared result. It may have been mistyped, or the account that shared it was deleted."
      />
    );
  }
  if (state.status === "unavailable") {
    return (
      <ShareNotice
        title="Shared result"
        text="This result could not be loaded right now. Try again in a minute."
      />
    );
  }

  const board = await getShareBoard(state.share.levelSlug);
  return (
    <Container className="pt-6 pb-16 sm:pb-24">
      <ShareCard share={state.share} board={board} />
    </Container>
  );
}
