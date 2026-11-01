import { Container } from "@/components/ui/container";
import { TextLink } from "@/components/ui/text-link";

/** A plain notice for a share link that cannot show a result, with a way home. Server-rendered. */
export function ShareNotice({ title, text }: { title: string; text: string }) {
  return (
    <Container className="pt-6 pb-16 sm:pb-24">
      <h1 className="text-[clamp(30px,11.4vw,44px)] leading-none tracking-[1px] uppercase sm:text-[56px]">
        {title}
      </h1>
      <p className="mt-5 max-w-[620px] text-lg leading-normal font-semibold text-mute">{text}</p>
      <div className="mt-6">
        <TextLink href="/">Algomind home</TextLink>
      </div>
    </Container>
  );
}
