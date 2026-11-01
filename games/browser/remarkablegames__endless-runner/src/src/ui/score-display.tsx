interface ScoreDisplayProps {
  scoreText: string;
  isVisible: boolean;
}

export function ScoreDisplay({ scoreText, isVisible }: ScoreDisplayProps) {
  if (!isVisible) {
    return null;
  }

  return (
    <div
      id="score-display"
      className="row-start-1 m-5 justify-self-end rounded-full border border-teal-400/25 bg-slate-950/70 px-4 py-3 text-sm tracking-wider uppercase backdrop-blur-md"
    >
      {scoreText}
    </div>
  );
}
