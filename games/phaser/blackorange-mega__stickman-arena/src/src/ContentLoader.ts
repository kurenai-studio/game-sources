import Phaser from "phaser";
import { assetPath } from "./config";
import type { CampaignDef, CharacterDef } from "./types";

/**
 * Loads and holds all JSON content, and knows how to queue the matching sprite
 * images into a scene's loader.
 *
 * Loading is split into two phases on purpose:
 *   1. `fetchData()` — plain async fetch of the JSON (done in BootScene).
 *   2. `queueSprites()` — registers images in a scene's loader, called from a
 *      scene's `preload()` so Phaser handles it natively (done in PreloadScene).
 *
 * Mixing Phaser's loader into an `async create()` is what caused scene
 * transitions to silently stall, so we keep the two concerns apart.
 */
export class GameContent {
  readonly campaign: CampaignDef;
  private readonly characters: Map<string, CharacterDef>;

  private constructor(campaign: CampaignDef, characters: Map<string, CharacterDef>) {
    this.campaign = campaign;
    this.characters = characters;
  }

  /** Look up a character definition by id (throws if missing — fail loud). */
  getCharacter(id: string): CharacterDef {
    const def = this.characters.get(id);
    if (!def) throw new Error(`Unknown character id "${id}" referenced in content.`);
    return def;
  }

  /** Texture key under which a character's sprite is registered in Phaser. */
  static textureKey(def: CharacterDef): string {
    return `sprite:${def.id}`;
  }

  /** Phase 1: fetch the campaign + every referenced character's JSON. */
  static async fetchData(): Promise<GameContent> {
    const campaign = await fetchJson<CampaignDef>("content/stages.json");

    // Collect the unique character ids we need: the player plus every enemy.
    const ids = new Set<string>([campaign.player]);
    for (const stage of campaign.stages) ids.add(stage.enemy);

    const characters = new Map<string, CharacterDef>();
    await Promise.all(
      [...ids].map(async (id) => {
        const def = await fetchJson<CharacterDef>(`content/characters/${id}.json`);
        characters.set(id, def);
      })
    );

    return new GameContent(campaign, characters);
  }

  /** Phase 2: queue each unique sprite in a scene's loader (call in preload). */
  queueSprites(scene: Phaser.Scene): void {
    const queued = new Set<string>();
    for (const def of this.characters.values()) {
      const key = GameContent.textureKey(def);
      if (queued.has(key)) continue;
      queued.add(key);
      // SVGs are rasterized at this size; raise it for crisper custom art.
      scene.load.svg(key, assetPath(def.sprite), { width: 120, height: 200 });
    }
  }
}

/** Fetch + parse a JSON file from the public content folder. */
async function fetchJson<T>(relativePath: string): Promise<T> {
  const res = await fetch(assetPath(relativePath));
  if (!res.ok) throw new Error(`Failed to load ${relativePath}: ${res.status}`);
  return (await res.json()) as T;
}
