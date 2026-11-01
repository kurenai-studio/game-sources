import { Key } from "@/components/ui/key";
import { LevelCard } from "@/components/public/level-card";
import { Caption } from "@/components/ui/caption";
import { levelCount, type World } from "@/lib/campaign";

/** A world: its idea, then each chapter with the levels in it. */
export function WorldSection({ world }: { world: World }) {
  const levels = levelCount(world);
  const chapters = world.chapters.length;
  return (
    <>
      <div className="flex items-start gap-5">
        <Key tone="ink" className="flex-none">
          <span
            aria-hidden="true"
            className="tile flex h-14 w-14 items-center justify-center bg-ink text-2xl text-on-ink tabular-nums"
          >
            {String(world.number).padStart(2, "0")}
          </span>
        </Key>
        <div>
          <Caption>{`World ${world.number}`}</Caption>
          <h2
            id={`world-${world.number}-title`}
            className="text-[32px] leading-none tracking-[0.5px] uppercase sm:text-[40px]"
          >
            {world.title}
          </h2>
        </div>
      </div>
      <p className="mt-4 max-w-[560px] text-base leading-normal font-semibold text-mute">
        {world.summary}
      </p>
      <p className="mt-2 text-xs font-bold tracking-[2px] text-mute uppercase">
        {`${chapters} ${chapters === 1 ? "chapter" : "chapters"} · ${levels} levels`}
      </p>
      {world.chapters.map((chapter, index) => (
        <div key={chapter.id} className="mt-10">
          <h3 className="text-[22px] leading-none tracking-[1px] uppercase">
            <span className="mr-3 text-sm tracking-[2px] text-mute">{`Chapter ${index + 1}`}</span>
            {chapter.title}
          </h3>
          <ul className="mt-5 grid grid-cols-2 gap-x-5 gap-y-8 sm:grid-cols-3 lg:grid-cols-4">
            {chapter.levels.map((level) => (
              <LevelCard key={level.slug} level={level} />
            ))}
          </ul>
        </div>
      ))}
    </>
  );
}
