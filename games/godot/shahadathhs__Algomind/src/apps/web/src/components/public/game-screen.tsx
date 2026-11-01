import { GameScreenView, type GameScreenState } from "./game-screen-view";
import { frameFor, screenData, tapeCount } from "./game-screen/frames";

export { SCREEN_HEIGHT, SCREEN_WIDTH, type GameScreenState } from "./game-screen-view";

/** A game screen of the landing level in one of its four states. */
export function GameScreen({ state, className }: { state: GameScreenState; className?: string }) {
  return (
    <GameScreenView
      state={state}
      frame={frameFor(state)}
      data={screenData()}
      count={tapeCount(state)}
      className={className}
    />
  );
}
