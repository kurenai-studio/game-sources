import { ButtonGraphic } from "@/components/ui/button-graphic";
import { COMMAND_LABEL, type Command } from "@/lib/board";
import { SvgCaption } from "./svg-text";

export function Commands() {
  const commands: Command[] = ["move", "left", "right"];
  return (
    <g>
      <SvgCaption x={20} y={640}>
        COMMANDS
      </SvgCaption>
      {commands.map((command, i) => (
        <ButtonGraphic
          look="depth"
          key={command}
          x={20 + i * 120}
          y={650}
          w={110}
          h={50}
          label={COMMAND_LABEL[command]}
          icon={command}
          fontSize={13}
        />
      ))}
    </g>
  );
}
