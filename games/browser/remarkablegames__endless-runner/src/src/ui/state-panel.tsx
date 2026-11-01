export interface PanelContent {
  title: string;
  message: string;
  buttonLabel: string;
}

interface StatePanelProps {
  content: PanelContent | null;
  onPrimaryAction: () => void;
}

export function StatePanel({ content, onPrimaryAction }: StatePanelProps) {
  if (content === null) {
    return null;
  }

  return (
    <div
      id="state-panel"
      className="pointer-events-auto row-start-2 max-w-112 place-self-center rounded-3xl border border-teal-400/20 bg-slate-950/80 p-8 text-center shadow-2xl backdrop-blur-md"
    >
      <h1 className="mb-3 text-[clamp(2.2rem,4vw,3.4rem)] tracking-[0.06em] uppercase">
        {content.title}
      </h1>
      <p className="mb-6 leading-6 text-slate-50/80">{content.message}</p>
      <button
        type="button"
        className="cursor-pointer rounded-full border border-teal-400/40 bg-linear-to-br from-cyan-400 to-blue-500 px-5 py-3.5 text-base font-bold text-slate-950 shadow-lg transition duration-150 ease-in-out hover:-translate-y-0.5 hover:shadow-xl hover:brightness-110 active:translate-y-0 active:shadow-md"
        onClick={onPrimaryAction}
      >
        {content.buttonLabel}
      </button>
    </div>
  );
}
