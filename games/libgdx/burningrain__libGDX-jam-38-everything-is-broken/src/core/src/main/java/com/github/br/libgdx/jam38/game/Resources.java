package com.github.br.libgdx.jam38.game;

public interface Resources {

    String SKIN_ATLAS = "skin/export/export.atlas";
    String SKIN = "skin/export/export.json";

    interface Tiled {
        String MENU = "tiled-packed/menu.tmx";
        String GAME = "tiled-packed/game.tmx";
    }

    String GRAPH_GAME_ATLAS = "pictures/graph_game.atlas";
    interface GraphGame {

        String BACKGROUND = "pictures/background.png";

        interface Button {
            String BURN_BUTTON = "burn_button";
            String EMITTER_BUTTON = "emitter_button";
            String EMPTY_BUTTON = "empty_button";
            String FREEZE_BUTTON = "freeze_button";

            String RESTART_BUTTON = "restart_button";
            String NEXT_BUTTON = "next_button";
        }

        interface Node {
            String EMITTER_NODE = "emitter_node";
            String EMPTY_NODE = "empty_node";
            String FREEZE_NODE = "freeze_node";
            String TARGET_NODE = "target_node";

            String SELECTED_EFFECT = "select_node";
        }

        interface Edge {
            String EMIT_EDGE = "emit_edge";
            String EMPTY_EDGE = "empty_edge";
            String FREEZE_EDGE = "freeze_edge";
            String TARGET_EDGE = "target_edge";
        }

        interface EmitterEffect {
            String EMITTER_FROM = "emitter_from";
            String EMITTER_FROM_TIME = "emitter_from_time";
            String EMITTER_TO = "emitter_to";
        }

        interface Sphere {
            String CREATION = "sphere_creation";
            String FAMILY = "sphere_family";
            String FRIENDSHIP = "sphere_frendship";
            String GLORY = "sphere_glory";
            String HEALTH = "sphere_health";
            String KNOWING = "sphere_knowing";
            String MONEY = "sphere_money";
            String REST = "sphere_rest";
            String SOUL = "sphere_soul";
            String WORK = "sphere_work";
        }

        String TIME = "time";

    }

}
