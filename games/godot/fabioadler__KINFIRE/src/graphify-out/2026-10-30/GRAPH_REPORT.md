# Graph Report - KINFIRE  (2026-10-30)

## Corpus Check
- 522 files · ~248,858 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 480 nodes · 666 edges · 39 communities (23 shown, 16 thin omitted)
- Extraction: 68% EXTRACTED · 32% INFERRED · 0% AMBIGUOUS · INFERRED: 212 edges (avg confidence: 0.89)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Combat & Inventory Mechanics
- Core Systems & Game Engine
- Asset Licensing & Attribution
- UI Panels & HUD Widgets
- Bug Fix & Item Tasks
- Audit Test Simulator Suite
- Lore Arc & Narrative Quests
- Character Animation & Sprites
- Bug Fix Ledger & Workflow
- Sprite Sheet Atlas & Tiles
- Quest Progression & Signals
- Quest Objectives & Tracking
- Audit Delivery & Documentation
- Brasa & Bonds UI Integration
- Typography & Font Licensing
- Guardian NPCs & Dialogues
- Master Plan Progress Tracking
- Runtime Hooks & Playtesting
- Kinfire Lore & Mythos
- Contracts & Crafting Backlog
- Audit Bug Remediation
- Game Architecture Singletons
- Lore Implementation SDD Plan
- Playthrough Verification Metrics
- Lore Coverage Metrics
- Armor Icon Assets
- Maldrach & Veil Mythos
- Audit Test Shell Scripts
- Lore Integration Phase Complete
- Endings Phase Complete
- Playtest Readiness Status
- Verification Checklist Artifact
- Armor04 Icon Asset
- Shoes01 Icon Asset
- Final Audit Report Doc
- Playthrough Final Report Doc
- 50-Level Test Script

## God Nodes (most connected - your core abstractions)
1. `Idle Animation State` - 18 edges
2. `Run Animation State` - 18 edges
3. `Playable Character Sprites` - 15 edges
4. `AuditTest` - 14 edges
5. `README Main` - 13 edges
6. `Task 1: Fix Tutorial Progression & Quest Stage Advancement` - 12 edges
7. `Audit Results Summary: 50/50 levels, 9/9 equipment tests, 0 errors/critical/bugs, 5 expected warnings, 29 bugs verified fixed, 0.60s duration` - 12 edges
8. `KINFIRE Bug Fixes Implementation Plan` - 11 edges
9. `REGRAS_DO_JOGO Canonical Rules` - 10 edges
10. `Task 1 Description: Fix Tutorial Progression Bug` - 10 edges

## Surprising Connections (you probably didn't know these)
- `test_equip_problem_checks()` --semantically_similar_to--> `equip_from_inventory()`  [INFERRED] [semantically similar]
  tests/test_equipment_system.gd → .superpowers/sdd/inventory-refactor/PLAYTHROUGH_TEST_REPORT.md
- `test_equipment_slots_exist()` --references--> `Equipment Slots System (DB.EQUIP_SLOTS)`  [INFERRED]
  tests/test_equipment_system.gd → scripts/autoload/db.gd
- `test_item_name_not_display_name()` --references--> `Fix: item.display_name → item.name`  [INFERRED]
  tests/test_equipment_system.gd → .superpowers/sdd/inventory-refactor/AUDIT_REPORT.md
- `Fix: inventory_get_count() → count_item()` --conceptually_related_to--> `count_item() method`  [INFERRED]
  .superpowers/sdd/inventory-refactor/AUDIT_REPORT.md → scripts/core/hero.gd
- `Fix: item.display_name → item.name` --conceptually_related_to--> `Item.name property`  [INFERRED]
  .superpowers/sdd/inventory-refactor/AUDIT_REPORT.md → scripts/core/hero.gd

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **SDD Task Sequence** — _superpowers_sdd_kinfire_lore_impl_progress_task_1, _superpowers_sdd_kinfire_lore_impl_progress_task_3, _superpowers_sdd_kinfire_lore_impl_progress_task_4_5, _superpowers_sdd_kinfire_lore_impl_progress_task_6, _superpowers_sdd_kinfire_lore_impl_progress_task_7, _superpowers_sdd_kinfire_lore_impl_progress_task_8, _superpowers_sdd_kinfire_lore_impl_progress_task_9, _superpowers_sdd_kinfire_lore_impl_progress_task_10_11, _superpowers_sdd_kinfire_lore_impl_progress_task_13_14, _superpowers_sdd_kinfire_lore_impl_progress_task_15 [EXTRACTED 1.00]
- **Brasa/Bonds Runtime Stack** — _superpowers_sdd_kinfire_lore_impl_verification_brasa_system, _superpowers_sdd_kinfire_lore_impl_verification_brasa_indicator, _superpowers_sdd_kinfire_lore_impl_verification_bonds_system, _superpowers_sdd_kinfire_lore_impl_verification_bonds_indicator, _superpowers_sdd_kinfire_lore_impl_verification_lore_system_manager [EXTRACTED 1.00]
- **Seven Guardians** — _superpowers_sdd_kinfire_lore_impl_verification_mira_pe_leve, _superpowers_sdd_kinfire_lore_impl_verification_ashara_sussurra_magia, _superpowers_sdd_kinfire_lore_impl_verification_lorelyn_espelho_d_agua, _superpowers_sdd_kinfire_lore_impl_verification_theron_pedra_ressoante, _superpowers_sdd_kinfire_lore_impl_verification_kael_abismo, _superpowers_sdd_kinfire_lore_impl_verification_khalid_areias_douradas, _superpowers_sdd_kinfire_lore_impl_verification_pyros_chama_ardente [EXTRACTED 1.00]
- **Audit Documentation Suite** — audit_delivery_final_audit_delivery, audit_preliminary_report_preliminary_report, audit_quick_start_quick_start_guide, audit_readme_audit_readme, readme_audit_readme_audit, start_audit_start_audit [EXTRACTED 1.00]
- **Critical Bug Fixes (inventory_get_count, item.display_name, panel.show_message)** — bug_inventory_get_count_missing, bug_item_display_name_missing, bug_panel_show_message_missing, fix_inventory_get_count_to_count_item, fix_item_display_name_to_name, fix_panel_show_message_to_hud, commit_967cf6a, commit_4aae3ff [EXTRACTED 1.00]
- **InventoryPanel Related Tasks** — docs_superpowers_plans_2026_10_30_kinfire_bug_fixes_task5, docs_superpowers_plans_2026_10_30_kinfire_bug_fixes_task6 [EXTRACTED 1.00]
- **QuestLog Related Tasks** — docs_superpowers_plans_2026_10_30_kinfire_bug_fixes_task1, docs_superpowers_plans_2026_10_30_kinfire_bug_fixes_task2 [EXTRACTED 1.00]
- **SkillTreePanel Related Tasks** — docs_superpowers_plans_2026_10_30_kinfire_bug_fixes_task3, docs_superpowers_plans_2026_10_30_kinfire_bug_fixes_task4 [EXTRACTED 1.00]
- **Equipment System Expansion (gloves + 3 accessory slots)** — equip_slots_system, slot_names_mapping, new_gloves_slot, new_accessory_slots, paper_doll_layout, scripts_core_hero_equipment_initialization, scripts_autoload_db_gd, scripts_ui_inventory_panel_gd, scripts_core_hero_gd, commit_3b8cf5a [EXTRACTED 1.00]
- **Equipment Integration Test Suite (6 tests)** — tests_test_equipment_system_gd, test_equipment_slots_exist, test_hero_equipment_initialization, test_equip_in_all_slots, test_unequip, test_equip_problem_checks, test_item_name_not_display_name, commit_4e28689 [EXTRACTED 1.00]
- **Full Playthrough Audit Scope** — superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_9_brief_doc, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_9_brief_test_scene, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_9_brief_six_phase_audit, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_9_report_audit_results_summary [EXTRACTED 1.00]
- **Full Playthrough Audit Scope** — superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_9_brief_doc, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_9_brief_test_scene, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_9_brief_six_phase_audit, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_9_report_audit_results_summary [EXTRACTED 1.00]
- **Lore Narrative Core** — lore_lore_bible, seven_flames_seven_flames, seven_guardians_seven_guardians, maldrach_maldrach, ithariel_ithariel, kinfire_kinfire, veil_of_discord_veil, eight_mysteries_mysteries, two_endings_endings [EXTRACTED 1.00]
- **OFL-Licensed Font Family** — assets_licenses_alegreya_ofl_alegreya_font, assets_licenses_cinzel_ofl_cinzel_font, assets_licenses_alegreya_ofl_sil_ofl_1_1 [EXTRACTED 1.00]
- **SDD Bug Fix Plan Tasks** — superpowers_sdd_2026-10-30-kinfire-bug-fixes_progress_task_1, superpowers_sdd_2026-10-30-kinfire-bug-fixes_progress_task_2, superpowers_sdd_2026-10-30-kinfire-bug-fixes_progress_task_3, superpowers_sdd_2026-10-30-kinfire-bug-fixes_progress_task_4, superpowers_sdd_2026-10-30-kinfire-bug-fixes_progress_task_5, superpowers_sdd_2026-10-30-kinfire-bug-fixes_progress_task_6, superpowers_sdd_2026-10-30-kinfire-bug-fixes_progress_task_7, superpowers_sdd_2026-10-30-kinfire-bug-fixes_progress_task_8, superpowers_sdd_2026-10-30-kinfire-bug-fixes_progress_task_9 [EXTRACTED 1.00]
- **Task 1 Quest Log Fix Flow** — superpowers_sdd_2026-10-30-kinfire-bug-fixes_task-1-brief_notify_flag_function, superpowers_sdd_2026-10-30-kinfire-bug-fixes_task-1-brief_check_stage_function, superpowers_sdd_2026-10-30-kinfire-bug-fixes_task-1-brief_recalc_function, superpowers_sdd_2026-10-30-kinfire-bug-fixes_task-1-brief_start_function [EXTRACTED 1.00]
- **Task 2 HUD Quest Tracker Flow** — superpowers_sdd_2026-10-30-kinfire-bug-fixes_task-2-brief_hud_gd, superpowers_sdd_2026-10-30-kinfire-bug-fixes_task-2-brief_update_quest_tracker_function, superpowers_sdd_2026-10-30-kinfire-bug-fixes_task-2-report_existing_tracked_quest_method, superpowers_sdd_2026-10-30-kinfire-bug-fixes_task-2-report_game_quests [EXTRACTED 1.00]
- **UI Panel Bug Fix Tasks (3-8)** — superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_3_brief_doc, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_4_brief_doc, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_5_brief_doc, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_6_brief_doc, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_7_brief_doc, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_8_brief_doc [INFERRED 0.75]
- **UI Panel Bug Fix Tasks (3-8)** — superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_3_brief_doc, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_4_brief_doc, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_5_brief_doc, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_6_brief_doc, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_7_brief_doc, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_8_brief_doc [INFERRED 0.75]
- **All Character Classes with Idle/Run/Hit Animations** — assets_sprites_dt2_tile_list_wizzard_female, assets_sprites_dt2_tile_list_wizzard_male, assets_sprites_dt2_tile_list_knight_female, assets_sprites_dt2_tile_list_knight_male, assets_sprites_dt2_tile_list_dwarf_male, assets_sprites_dt2_tile_list_dwarf_female, assets_sprites_dt2_tile_list_lizard_female, assets_sprites_dt2_tile_list_lizard_male, assets_sprites_dt2_tile_list_elf_female, assets_sprites_dt2_tile_list_elf_male [INFERRED 0.85]
- **Orc Family Variants Sharing Sprite Dimensions** — assets_sprites_dt2_tile_list_orc_variants, assets_sprites_dt2_tile_list_animation_idle, assets_sprites_dt2_tile_list_animation_run [INFERRED 0.85]
- **Core Game Systems** — overworld_procedural_overworld, dungeon_generator_dungeon_gen, enemy_rarity_system_enemy_rarity, combat_system_combat, dialogue_system_dialogue, quest_system_quest, economy_market_economy [INFERRED 0.85]
- **Inventory and UI Coordination Fixes** — superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_5_brief_hero_sprite_doll, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_5_brief_inventory_panel_gd, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_6_brief_sell_junk, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_7_brief_inventory_signal_hook, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_7_brief_hud_gd [INFERRED 0.85]
- **Inventory and UI Coordination Fixes** — superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_5_brief_hero_sprite_doll, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_5_brief_inventory_panel_gd, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_6_brief_sell_junk, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_7_brief_inventory_signal_hook, superpowers_sdd_2026_10_30_kinfire_bug_fixes_task_7_brief_hud_gd [INFERRED 0.85]
- **Large Enemy Types (32x36) with Idle/Run Animations** — assets_sprites_dt2_tile_list_big_demon, assets_sprites_dt2_tile_list_big_zombie, assets_sprites_dt2_tile_list_ogre [INFERRED 0.95]
- **CC0-Licensed Game Asset Collection** — assets_licenses_0x72_dungeontileset_ii_0x72_dungeontileset_ii, assets_licenses_kenney_impact_sounds_impact_sounds, assets_licenses_kenney_roguelike_rpg_pack_roguelike_pack, assets_licenses_kenney_rpg_audio_rpg_audio, assets_licenses_kenney_tiny_dungeon_tiny_dungeon, assets_licenses_kenney_ui_rpg_ui_pack_rpg_extension, assets_licenses_music_music_dungeon, assets_licenses_rpg_icons_7soul1_rpg_icons [INFERRED 0.95]
- **Consumables Bug Fixes (Tasks 1-2)** — _superpowers_sdd_bugfix_ledger_task_1_consumables_add_item_use, _superpowers_sdd_bugfix_ledger_task_2_consumables_decrement_count, item_gd_use_function, item_gd_inventory_removal [INFERRED 0.95]
- **Dialogue Flow Refactor (Task 5)** — _superpowers_sdd_bugfix_ledger_task_5_dialogue_select_choice, dialogue_show_page_function, dialogue_advance_or_close_function, dialogue_select_choice_function, dialogue_current_node_variable [INFERRED 0.95]
- **Kenney Asset Pack Family (CC0 Licensed)** — assets_licenses_kenney_impact_sounds_impact_sounds, assets_licenses_kenney_roguelike_rpg_pack_roguelike_pack, assets_licenses_kenney_rpg_audio_rpg_audio, assets_licenses_kenney_tiny_dungeon_tiny_dungeon, assets_licenses_kenney_ui_rpg_ui_pack_rpg_extension [INFERRED 0.95]
- **Skills System Bug Fixes (Tasks 3-4)** — _superpowers_sdd_bugfix_ledger_task_3_skills_add_player_use_skill, _superpowers_sdd_bugfix_ledger_task_4_skills_tree_dependent_nodes, player_gd_use_skill_function, player_gd_request_cast_function, skill_tree_panel_gd_refresh_function, skill_tree_panel_gd_update_node_ui_function [INFERRED 0.95]

## Communities (39 total, 16 thin omitted)

### Community 0 - "Combat & Inventory Mechanics"
Cohesion: 0.08
Nodes (32): add_buff() method, apply_poison() method, Missing inventory_get_count() method, Missing item.display_name property, Signal Memory Leak (missing disconnect), Missing panel.show_message() method, Commit 3b8cf5a - feat gloves and accessories, Commit 4aae3ff - fix critical bugs (+24 more)

### Community 1 - "Core Systems & Game Engine"
Cohesion: 0.06
Nodes (48): Audio System, Autoload Singletons, Bonds System, Brasa System, Champion Affixes, 14 Classes, Combat System (SkillExecutor), Data-Driven Architecture (+40 more)

### Community 2 - "Asset Licensing & Attribution"
Cohesion: 0.05
Nodes (42): 0x72 (Creator), 0x72 DungeonTileset II v1.7, CC0 (Public Domain) License, itch.io Platform, CC0 (Public Domain) License, Donate to Kenney, Impact Sounds v1.0, Kenney (Kenney Vleugels) (+34 more)

### Community 3 - "UI Panels & HUD Widgets"
Cohesion: 0.08
Nodes (40): _calculate_depths() function, Depth normalization rationale: shift negative depths so root starts at column 0, Task 3 Brief, scripts/ui/skill_tree_panel.gd, Commit 1ccfd2c: Fix skill tree depth calculation, Task 3 Report, Bezier connection curves (right-to-left drawing, left-to-right visual flow), _canvas_draw() function (+32 more)

### Community 4 - "Bug Fix & Item Tasks"
Cohesion: 0.14
Nodes (36): DT2 Sprite Sheet Tile List, Animation Frame Convention (f0-f3), Hit Animation State, Idle Animation State, Run Animation State, Big Demon Character (32x36), Big Zombie Character (32x36), Playable Character Sprites (+28 more)

### Community 5 - "Audit Test Simulator Suite"
Cohesion: 0.09
Nodes (31): _build_bottom_bar() method in HUD, _calculate_depths() method in SkillTreePanel, _canvas_draw() method in SkillTreePanel, Character Status Minus Button Bug, CharacterPanel (scripts/ui/character_panel.gd), GDScript, Godot 4.7.2 (Flatpak), Headless Test Execution (+23 more)

### Community 6 - "Lore Arc & Narrative Quests"
Cohesion: 0.09
Nodes (28): KINFIRE 7 Medium Bugs Fix Plan, Task 10: Run full simulation and verify regressions, Task 1: CONSUMABLES — Add Item.use() (CRITICAL: crash when using consumable), Task 2: CONSUMABLES — Decrement item count after use (MEDIUM), Task 3: SKILLS — Add Player._use_skill() (CRITICAL: crash when clicking skill slot in HUD), Task 4: SKILLS — Tree: dependent nodes not updated after purchase (MEDIUM), Task 5: DIALOGUE — _select_choice closes even when next_id is defined (MEDIUM), Task 6: STRINGS — %d used for float values (armor, max_hp) (MEDIUM) (+20 more)

### Community 7 - "Character Animation & Sprites"
Cohesion: 0.09
Nodes (16): datetime, json, pathlib, AuditTest, main(), FASE 3: Criação de Personagem, FASE 4: Gameplay - 50 níveis, FASE 5: Testes de Sistemas (+8 more)

### Community 8 - "Bug Fix Ledger & Workflow"
Cohesion: 0.09
Nodes (23): Task 3: Cinzento → Ithariel Reveal, Task 6: Véu da Discórdia, Task 7: Kinfire Dungeon, Task 8: Quest Chain Linking, Task 9: Integration & Polish, Act 3 Dialogue Branches, arrependimento Path, Ato3_1 Bonds Completion Gate (+15 more)

### Community 9 - "Sprite Sheet Atlas & Tiles"
Cohesion: 0.10
Nodes (21): Plan File: 2026-10-30-kinfire-bug-fixes.md, SDD Ledger, Task 2: Add Missing tracked_quest() Method to QuestLog, Task 3, Task 4, Task 5, Task 6, Task 7 (+13 more)

### Community 10 - "Quest Progression & Signals"
Cohesion: 0.23
Nodes (15): Task 1: Fix Tutorial Progression & Quest Stage Advancement, _check_stage() function, COLLECT objectives, FLAG objectives, notify_flag() function, scripts/core/quest_log.gd, _recalc() function, start() function (+7 more)

### Community 11 - "Quest Objectives & Tracking"
Cohesion: 0.23
Nodes (14): _check_stage() method in QuestLog, DB.quest() function, _event() method in QuestLog, Game.flags dictionary, Prologue (scripts/game/prologue.gd), Quest Stage Advancement Bug, quest_advanced signal, quest_completed signal (+6 more)

### Community 12 - "Audit Delivery & Documentation"
Cohesion: 0.26
Nodes (13): Audit Delivery Final, Preliminary Audit Report, Quick Start Guide, Audit README, Test Full Playthrough Audit, README Audit, Run Audit Test Script, 7 High Bugs (+5 more)

### Community 13 - "Brasa & Bonds UI Integration"
Cohesion: 0.24
Nodes (12): Task 10-11: UI + Lore System Integration, Task 4-5: Brasa + Bonds Systems, all_bonds_collected Signal, bonds_changed Signal, BondsIndicator UI, BondsSystem Class, brasa_changed Signal, BrasaIndicator UI (+4 more)

### Community 14 - "Typography & Font Licensing"
Cohesion: 0.18
Nodes (12): Alegreya Font, The Alegreya Project Authors, Author (OFL Definition), Font Software (OFL Definition), Huerta Tipográfica, Modified Version, Original Version, Reserved Font Name (+4 more)

### Community 15 - "Guardian NPCs & Dialogues"
Cohesion: 0.22
Nodes (9): Task 1: Guardian NPCs + Dialogues, Ashara "Sussurra-Magia" (Floresta Crepúsculo), Guardian System, Kael "Abismo" (Caverna Obsidiana), Khalid "Areias-Douradas" (Deserto Ouro), Lorelyn "Espelho-d'Água" (Águas Cristalinas), Mira "Pé-Leve" (Planícies), Pyros "Chama-Ardente" (Vulcão Escarlate) (+1 more)

### Community 16 - "Master Plan Progress Tracking"
Cohesion: 0.38
Nodes (7): 11 Phases Complete, 58 Commits, PLANO Master Progress, Production Ready, Status Final, ~20,000 Lines of GDScript, 200+ .tres Resources

### Community 17 - "Runtime Hooks & Playtesting"
Cohesion: 0.33
Nodes (6): Pending Tasks 10-12: UI, Runtime Hooks, Playtest, Brasa Zone System, Next Steps (Runtime Integration), Playtest Paths, Quest NPC Routing, UI Integration

### Community 18 - "Kinfire Lore & Mythos"
Cohesion: 0.33
Nodes (6): Door Tiles (Frames, Leaves Open/Closed), Environment/Tile Sprites, Floor Tile Variants, Wall Fountain Tiles (Red/Blue, Basin/Top), Interactive Tiles (Buttons, Levers, Spikes, Ladder), Wall Tile Variants

### Community 20 - "Audit Bug Remediation"
Cohesion: 0.50
Nodes (4): Corrections Applied, Final Corrections Report, 6 Critical/High Bugs Fixed, 21 Bugs Fixed Total

### Community 21 - "Game Architecture Singletons"
Cohesion: 0.50
Nodes (4): DB Singleton, Game Singleton, KINFIRE Game, Performance Metrics (Memory, Time)

### Community 22 - "Lore Implementation SDD Plan"
Cohesion: 0.67
Nodes (3): BASE Commit: dce437e, Plan Reference: 2026-10-28-kinfire-lore-implementation.md, SDD Ledger

### Community 23 - "Playthrough Verification Metrics"
Cohesion: 1.00
Nodes (3): 50 Levels Completed, Playthrough Real Report, Zero Critical Errors After Fix

## Ambiguous Edges - Review These
- `player.gd` → `dungeon_generator.gd while true loop`  [AMBIGUOUS]
  .superpowers/sdd/inventory-refactor/AUDIT_REPORT.md · relation: references

## Knowledge Gaps
- **148 isolated node(s):** `run_audit_test.sh script`, `dungeon_generator.gd while true loop`, `get_tree_node_rank() method`, `Slot Names Mapping (DB.SLOT_NAMES)`, `take_damage() method` (+143 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 176 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **16 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `player.gd` and `dungeon_generator.gd while true loop`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **Why does `KINFIRE Bug Fixes Implementation Plan` connect `Audit Test Simulator Suite` to `Quest Objectives & Tracking`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **Why does `DT2 Sprite Sheet Atlas` connect `Bug Fix & Item Tasks` to `Kinfire Lore & Mythos`?**
  _High betweenness centrality (0.005) - this node is a cross-community bridge._
- **Are the 18 inferred relationships involving `Idle Animation State` (e.g. with `Big Demon Character (32x36)` and `Big Zombie Character (32x36)`) actually correct?**
  _`Idle Animation State` has 18 INFERRED edges - model-reasoned connections that need verification._
- **Are the 18 inferred relationships involving `Run Animation State` (e.g. with `Big Demon Character (32x36)` and `Big Zombie Character (32x36)`) actually correct?**
  _`Run Animation State` has 18 INFERRED edges - model-reasoned connections that need verification._
- **Are the 15 inferred relationships involving `Playable Character Sprites` (e.g. with `Big Demon Character (32x36)` and `Big Zombie Character (32x36)`) actually correct?**
  _`Playable Character Sprites` has 15 INFERRED edges - model-reasoned connections that need verification._
- **What connects `run_audit_test.sh script`, `dungeon_generator.gd while true loop`, `get_tree_node_rank() method` to the rest of the system?**
  _148 weakly-connected nodes found - possible documentation gaps or missing edges._