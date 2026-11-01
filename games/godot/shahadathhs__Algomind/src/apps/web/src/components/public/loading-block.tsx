import { Container } from "@/components/ui/container";
import { Rule } from "@/components/ui/rule";

/**
 * What a section shows while its data is on the way: a rule, a caption and quiet outlined tiles, so the
 * page already has its shape. Nothing in it moves (nothing loops while idle); `role="status"` tells a
 * screen reader that something is loading.
 */
export function LoadingBlock({
  label,
  tiles = 5,
  tall = false,
}: {
  /** What is loading, in plain words ("levels"). */
  label: string;
  tiles?: number;
  /** Taller tiles, for boards. */
  tall?: boolean;
}) {
  return (
    <section>
      <Container>
        <Rule />
        <div role="status" data-loading="" className="py-12 sm:py-[72px]">
          <p className="text-xs font-bold tracking-[2px] text-mute uppercase">{`Loading ${label}`}</p>
          <ul aria-hidden="true" className="mt-8 grid grid-cols-2 gap-x-5 gap-y-6 sm:grid-cols-5">
            {Array.from({ length: tiles }, (_, i) => (
              <li
                key={i}
                className={`tile border-2 border-faint ${tall ? "h-40 sm:h-44" : "h-24"}`}
                style={{ ["--chamfer" as string]: "12px" }}
              />
            ))}
          </ul>
        </div>
      </Container>
    </section>
  );
}
