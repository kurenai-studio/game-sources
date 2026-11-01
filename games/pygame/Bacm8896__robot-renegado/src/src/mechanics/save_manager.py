"""Guardado por perfiles: un archivo por Operador en `saves/{nombre}.json`.

Cada archivo guarda la campaña completa (CampaignRun + recursos y progreso del ResourceManager) y el punto de reanudación:
el estado seguro al que vuelve «Continuar» (inicio de un sub-acto del Acto 1, la Base Central o el Terminal Táctico).
El autoguardado lo dispara el juego al terminar cada misión (Game.autosave); solo guarda perfiles con nombre.

Formato JSON con etiquetas para lo que JSON no tiene: conjuntos, bytes (niebla de guerra), Vector2 y el RewardTracker.
Los archivos sin `player_name` (partidas anteriores a los perfiles) se migran a `saves/Operador.json` sin perder progreso."""
import base64
import datetime
import json
import logging
import os
import re

from pygame.math import Vector2

from src.entities.building import LEGACY_STRUCTURES
from src.mechanics.rewards import RewardTracker

SAVE_VERSION = 1
DEFAULT_NAME = "Operador"
MAX_NAME = 12
SAVE_DIR = os.environ.get("RR_SAVE_DIR") or os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "saves")
_RESERVED = {"CON", "PRN", "AUX", "NUL", *(f"COM{i}" for i in range(1, 10)), *(f"LPT{i}" for i in range(1, 10))}
log = logging.getLogger(__name__)


# ------------------------------------------------------------------ nombres
def clean_name(name):
    """Nombre del Operador tal como se muestra: letras y números (también con tilde o ñ), máximo 12; vacío -> Operador."""
    kept = "".join(ch for ch in str(name or "") if ch.isalnum())[:MAX_NAME]
    return kept or DEFAULT_NAME


def file_stem(name):
    """Nombre de archivo válido en cualquier sistema: sin separadores ni caracteres prohibidos, sin nombres reservados de
    Windows (CON, NUL, COM1...) y sin puntos ni espacios al final."""
    stem = re.sub(r'[<>:"/\\|?*\x00-\x1f]', "", clean_name(name)).strip(" .")
    if not stem:
        stem = DEFAULT_NAME
    if stem.upper() in _RESERVED:
        stem += "_"
    return stem


def save_path(name, folder=None):
    return os.path.join(folder or SAVE_DIR, file_stem(name) + ".json")


# ------------------------------------------------------------------ codificación JSON con etiquetas
def encode(value):
    if isinstance(value, dict):
        if all(isinstance(k, str) for k in value):
            return {k: encode(v) for k, v in value.items()}
        return {"__map__": [[encode(k), encode(v)] for k, v in value.items()]}
    if isinstance(value, (set, frozenset)):
        return {"__set__": [encode(v) for v in sorted(value, key=repr)]}
    if isinstance(value, (list, tuple)):
        return [encode(v) for v in value]
    if isinstance(value, (bytes, bytearray)):
        return {"__bytes__": base64.b64encode(bytes(value)).decode("ascii")}
    if isinstance(value, Vector2):
        return {"__v2__": [value.x, value.y]}
    if isinstance(value, RewardTracker):
        return {"__rewards__": encode(vars(value))}
    if value is None or isinstance(value, (bool, int, float, str)):
        return value
    raise TypeError(f"no se puede guardar un {type(value).__name__}")


def decode(value):
    if isinstance(value, list):
        return [decode(v) for v in value]
    if not isinstance(value, dict):
        return value
    if "__set__" in value:
        return {decode(v) for v in value["__set__"]}
    if "__bytes__" in value:
        return base64.b64decode(value["__bytes__"])
    if "__v2__" in value:
        return Vector2(value["__v2__"])
    if "__map__" in value:
        return {_hashable(decode(k)): decode(v) for k, v in value["__map__"]}
    if "__rewards__" in value:
        tracker = RewardTracker()
        for k, v in decode(value["__rewards__"]).items():
            setattr(tracker, k, v)
        return tracker
    return {k: decode(v) for k, v in value.items()}


def _hashable(v):
    return tuple(_hashable(x) for x in v) if isinstance(v, list) else v


# ------------------------------------------------------------------ resumen del progreso (lista de Continuar)
def progress_summary(res):
    """Una línea con el progreso: dónde va la campaña y sus recursos."""
    if res.campaign_completed:
        stage = "Campaña completada"
    elif res.bunker_built:
        stage = "Acto 2 · Búnker ensamblado"
    elif res.initial_done:
        stage = f"Acto 2 · incursión nivel {res.incursion_level}"
    elif res.vulcano_online:
        stage = "Acto 1 · VULCANO en línea"
    elif res.aura_linked:
        stage = "Acto 1 · AURA enlazada"
    else:
        stage = "Acto 1"
    return f"{stage} · {res.metal} chatarra · {res.cores} núcleos"


# ------------------------------------------------------------------ guardar / cargar
def build_save(res, resume_state, resume_kwargs=None):
    run = res.campaign_run
    return {"version": SAVE_VERSION, "player_name": clean_name(run.player_name),
            "saved_at": datetime.datetime.now().isoformat(timespec="seconds"),
            "progress": progress_summary(res),
            "resume": {"state": resume_state, "kwargs": encode(dict(resume_kwargs or {}))},
            "campaign_run": encode(run.to_dict()), "resources": encode(res.to_save())}


def write(data, folder=None):
    """Escribe el perfil de forma atómica (archivo temporal + reemplazo). Devuelve la ruta."""
    folder = folder or SAVE_DIR
    os.makedirs(folder, exist_ok=True)
    path = save_path(data["player_name"], folder)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=1)
    os.replace(tmp, path)
    return path


def save_game(res, resume_state, resume_kwargs=None, folder=None):
    return write(build_save(res, resume_state, resume_kwargs), folder)


def read(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def migrate_structures(run_data, res_data):
    """Estructuras retiradas en partidas guardadas (el Generador) -> su sustituta (el Pilón), en la base del Terminal y en
    la base que viaja entre mapas de campaña. Devuelve cuántas convirtió."""
    changed = 0
    entries = list(res_data.get("base_layout") or [])
    entries += list((run_data.get("layout_data") or {}).get("buildings") or [])
    for entry in entries:
        if isinstance(entry, dict) and entry.get("type") in LEGACY_STRUCTURES:
            entry["type"] = LEGACY_STRUCTURES[entry["type"]]
            changed += 1
    return changed


def apply_save(res, data):
    """Carga el perfil en el ResourceManager (que debe venir de reset()). Devuelve (estado, kwargs) de reanudación."""
    from src.managers.resource_manager import CampaignRun        # import local: evita el ciclo con resource_manager
    run_data = decode(data.get("campaign_run") or {})
    res_data = decode(data.get("resources") or {})
    migrate_structures(run_data, res_data)
    run_data.setdefault("player_name", data.get("player_name") or DEFAULT_NAME)
    run_data["named"] = True
    res.campaign_run = CampaignRun.from_dict(run_data)
    res.load_save(res_data)
    resume = data.get("resume") or {}
    return resume.get("state"), decode(resume.get("kwargs") or {})


def migrate_legacy(folder=None):
    """Partidas sin `player_name` (anteriores a los perfiles): pasan a saves/Operador.json conservando todo el progreso.
    Si ya existe un Operador.json se conserva el más reciente. Devuelve cuántas migró."""
    folder = folder or SAVE_DIR
    if not os.path.isdir(folder):
        return 0
    moved = 0
    for fname in sorted(os.listdir(folder)):
        path = os.path.join(folder, fname)
        if not fname.endswith(".json") or not os.path.isfile(path):
            continue
        try:
            data = read(path)
        except (OSError, ValueError):
            continue
        if not isinstance(data, dict) or data.get("player_name"):
            continue
        data["player_name"] = DEFAULT_NAME
        run = data.get("campaign_run")
        if isinstance(run, dict):
            run.setdefault("player_name", DEFAULT_NAME)
        data.setdefault("saved_at", datetime.datetime.fromtimestamp(os.path.getmtime(path)).isoformat(timespec="seconds"))
        data.setdefault("progress", "Partida anterior")
        data.setdefault("version", SAVE_VERSION)
        data.setdefault("resume", {"state": None, "kwargs": {}})             # el juego deduce el punto de reanudación
        target = save_path(DEFAULT_NAME, folder)
        if os.path.abspath(target) != os.path.abspath(path):
            if os.path.exists(target) and read(target).get("saved_at", "") >= data["saved_at"]:
                os.replace(path, path + ".migrado")
                continue
            os.replace(path, path + ".migrado")                   # el original queda como copia de seguridad
        write(data, folder)
        moved += 1
    return moved


def list_profiles(folder=None):
    """Perfiles guardados, del más reciente al más antiguo: [{"name", "path", "saved_at", "progress"}]. Ignora los
    archivos dañados."""
    folder = folder or SAVE_DIR
    migrate_legacy(folder)
    out = []
    if not os.path.isdir(folder):
        return out
    for fname in os.listdir(folder):
        path = os.path.join(folder, fname)
        if not fname.endswith(".json"):
            continue
        try:
            data = read(path)
        except (OSError, ValueError) as exc:
            log.warning("perfil ilegible %s: %s", fname, exc)
            continue
        if not isinstance(data, dict) or "resume" not in data:
            continue
        out.append({"name": clean_name(data.get("player_name")), "path": path,
                    "saved_at": str(data.get("saved_at", "")), "progress": str(data.get("progress", ""))})
    out.sort(key=lambda p: p["saved_at"], reverse=True)
    return out


def delete_save_profile(player_name, folder=None, path=None):
    """Borra el perfil `saves/{player_name}.json` (y su temporal `.tmp` si quedó alguno). `path`: ruta exacta del archivo
    listado (si no, se deduce del nombre). Nunca toca nada fuera de la carpeta de guardados. True si el perfil se borró."""
    folder = os.path.abspath(folder or SAVE_DIR)
    target = os.path.abspath(path) if path else save_path(player_name, folder)
    if os.path.dirname(target) != folder or not target.endswith(".json"):
        log.warning("borrado rechazado fuera de la carpeta de guardados: %s", target)
        return False
    try:
        if os.path.exists(target + ".tmp"):
            os.remove(target + ".tmp")
        os.remove(target)
    except OSError as exc:
        log.warning("no se pudo borrar el perfil %s: %s", target, exc)
        return False
    return True


def find_profile(name, folder=None):
    """Perfil por nombre escrito (sin distinguir mayúsculas); si no hay uno exacto, el único que empiece así. None si no
    existe o es ambiguo."""
    want = clean_name(name).lower()
    profiles = list_profiles(folder)
    for p in profiles:
        if p["name"].lower() == want:
            return p
    starts = [p for p in profiles if p["name"].lower().startswith(want)]
    return starts[0] if len(starts) == 1 else None
