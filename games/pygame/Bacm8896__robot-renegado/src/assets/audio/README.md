# Audio de Robot Renegado

El `AudioManager` (`src/core/audio_manager.py`) busca aquí los archivos reales. Si falta alguno, ese efecto
se sintetiza al vuelo: el juego nunca queda mudo ni falla por un asset que falta.

## Efectos: `sfx/<nombre>.wav` o `.ogg`

| Archivo | Cuándo suena |
|---|---|
| `rifle` | Disparo del Operador |
| `dash` | Activación del Dash |
| `medkit` | [H] Botiquín: bloque de vida recuperado |
| `hit` | Impacto recibido por el Operador |
| `block_break` | Se vacía un bloque de vida |
| `build_mode` / `build_mode_off` | [ESPACIO] Modo Construcción / pausa táctica (entrar / salir) |
| `place` | Estructura colocada o terminada por VULCANO |
| `pylon_link` | Pilón conectado a la red |
| `text_aura` / `text_vulcano` / `text_sistema` | Teletipo de los diálogos |
| `crit` / `ricochet` | Golpe crítico / rebote en el blindaje del Ariete Ligero |
| `error` | Aviso de interfaz |

## Música: `music/<pista>.ogg`, `.mp3` o `.wav` (en bucle)

| Archivo | Dónde |
|---|---|
| `menu` | Menú principal |
| `base` | Base Central (modo Comandante) |

Sin archivo, cada pista usa un colchón ambiental sintetizado. Volúmenes por defecto en `config.py`
(`AUDIO_SFX_VOLUME`, `AUDIO_MUSIC_VOLUME`). `RR_AUDIO=off` fuerza el modo silencioso.
