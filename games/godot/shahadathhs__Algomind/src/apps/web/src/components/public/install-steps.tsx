import { Key } from "@/components/ui/key";
import { Caption } from "@/components/ui/caption";

const STEPS = [
  {
    title: "Download",
    text: "Tap Download APK. Your browser may warn that this type of file can harm your device.",
  },
  {
    title: "Open the file",
    text: "Open the downloaded file from your notifications or Files app.",
  },
  {
    title: "Allow install",
    text: "If asked, allow your browser to install unknown apps. This is a one-time setting.",
  },
  {
    title: "Open Algomind",
    text: "Open the app. Updates install over the old version.",
  },
];

/** Four numbered steps. Step 1 is the signal tile (the action you take on this page). */
export function InstallSteps() {
  return (
    <div className="min-w-0">
      <Caption>Install</Caption>
      <h2 className="mt-2 mb-6 text-[32px] leading-none tracking-[1px] uppercase">Four steps.</h2>
      <ol>
        {STEPS.map((step, i) => (
          <li key={step.title} className="flex gap-5 border-t-2 border-ink py-5">
            <Key tone={i === 0 ? "signal" : "ink"} className="shrink-0">
              <span
                aria-hidden="true"
                className={`tile flex h-12 w-12 items-center justify-center text-[22px] ${
                  i === 0 ? "bg-signal text-on-signal" : "bg-ink text-on-ink"
                }`}
                style={{ ["--chamfer" as string]: "12px" }}
              >
                {i + 1}
              </span>
            </Key>
            <div className="min-w-0">
              <h3 className="text-xl tracking-[1px] uppercase">
                <span className="sr-only">{`Step ${i + 1}: `}</span>
                {step.title}
              </h3>
              <p className="mt-1 text-[15px] leading-normal font-semibold tracking-[0.3px] text-mute">
                {step.text}
              </p>
            </div>
          </li>
        ))}
      </ol>
    </div>
  );
}
