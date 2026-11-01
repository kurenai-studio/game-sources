import { renderShareImage } from "@/lib/og";
import { getShare, resultText, shareCaption } from "@/lib/share";

/** The share preview for one code: the level, the numbers, and the caption. No player appears. */
export async function shareImageFor(code: string) {
  const state = await getShare(code);
  if (state.status !== "found") {
    return renderShareImage({ title: "Shared result", subtitle: "A result shared from Algomind." });
  }
  const { share } = state;
  return renderShareImage({
    title: share.title,
    subtitle: `${shareCaption(share)}. ${resultText(share)}.`,
  });
}
