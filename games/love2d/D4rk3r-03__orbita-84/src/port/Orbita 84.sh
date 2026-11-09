#!/bin/bash
# Órbita 84 — lanzador para PortMaster (RG36H / ArkOS)

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

GAMEDIR="/$directory/ports/orbita84"

cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

source $controlfolder/runtimes/"love_11.5"/love.txt

# el récord y los colores se guardan junto al juego
export XDG_DATA_HOME="$GAMEDIR/datos"
mkdir -p "$XDG_DATA_HOME"

$GPTOKEYB "$LOVE_GPTK" -c "$GAMEDIR/controls.gptk" &
pm_platform_helper "$LOVE_BINARY"

$LOVE_RUN "$GAMEDIR/orbita84.love"

pm_finish
