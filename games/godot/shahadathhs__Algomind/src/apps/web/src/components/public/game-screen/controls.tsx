import { ButtonGraphic } from "@/components/ui/button-graphic";
import type { GameScreenState } from "../game-screen-view";

export function Controls({ state }: { state: GameScreenState }) {
  const y = 714;
  const h = 56;
  switch (state) {
    case "ready":
      return (
        <g>
          <ButtonGraphic look="depth" x={20} y={y} w={96} h={h} label="STEP" icon="step" />
          <ButtonGraphic
            look="depth"
            x={126}
            y={y}
            w={146}
            h={h}
            label="RUN"
            icon="run"
            primary
            fontSize={15}
          />
          <ButtonGraphic look="depth" x={282} y={y} w={88} h={h} label="RESET" icon="reset" />
        </g>
      );
    case "running":
      return (
        <g>
          <ButtonGraphic look="depth" x={20} y={y} w={96} h={h} label="STEP" icon="step" />
          <ButtonGraphic
            look="depth"
            x={126}
            y={y}
            w={146}
            h={h}
            label="CONTINUE"
            icon="run"
            primary
            fontSize={15}
          />
          <ButtonGraphic look="depth" x={282} y={y} w={88} h={h} label="RESET" icon="reset" />
        </g>
      );
    case "failed":
      return (
        <g>
          <ButtonGraphic look="depth" x={20} y={y} w={96} h={h} label="RESET" icon="reset" />
          <ButtonGraphic
            look="depth"
            x={126}
            y={y}
            w={244}
            h={h}
            label="EDIT PROGRAM"
            primary
            fontSize={15}
          />
        </g>
      );
    case "solved":
      return (
        <g>
          <ButtonGraphic look="depth" x={20} y={y} w={96} h={h} label="LEVELS" />
          <ButtonGraphic look="depth" x={126} y={y} w={110} h={h} label="REPLAY" icon="reset" />
          <ButtonGraphic
            look="depth"
            x={246}
            y={y}
            w={124}
            h={h}
            label="NEXT"
            primary
            fontSize={15}
          />
        </g>
      );
  }
}
