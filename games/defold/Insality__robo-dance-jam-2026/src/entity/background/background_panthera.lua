return {
    data = {
        animations = {
            {
                animation_id = "default",
                animation_keys = {
                    {
                        duration = 15,
                        easing = "inoutsine",
                        end_value = -500,
                        key_type = "tween",
                        node_id = "stars",
                        property_id = "position_y",
                    },
                    {
                        duration = 15,
                        easing = "linear",
                        key_type = "animation",
                        node_id = "background_star_row1",
                        property_id = "left",
                    },
                    {
                        duration = 15,
                        easing = "linear",
                        key_type = "animation",
                        node_id = "background_star_row2",
                        property_id = "right",
                    },
                    {
                        duration = 15,
                        easing = "linear",
                        key_type = "animation",
                        node_id = "background_star_row3",
                        property_id = "left",
                    },
                    {
                        duration = 15,
                        easing = "linear",
                        key_type = "animation",
                        node_id = "background_star_row4",
                        property_id = "right",
                    },
                    {
                        duration = 15,
                        easing = "outinsine",
                        end_value = 250,
                        key_type = "tween",
                        node_id = "stars",
                        property_id = "position_x",
                    },
                },
                duration = 15,
            },
            {
                animation_id = "on_beat",
                animation_keys = {
                    {
                        duration = 0.15,
                        easing = "outsine",
                        end_value = 1.05,
                        key_type = "tween",
                        node_id = "group",
                        property_id = "scale_x",
                        start_value = 1,
                    },
                    {
                        duration = 0.15,
                        easing = "outsine",
                        end_value = 1.05,
                        key_type = "tween",
                        node_id = "group",
                        property_id = "scale_y",
                        start_value = 1,
                    },
                    {
                        duration = 0.45,
                        easing = "outback",
                        end_value = 1,
                        key_type = "tween",
                        node_id = "group",
                        property_id = "scale_x",
                        start_time = 0.15,
                        start_value = 1.05,
                    },
                    {
                        duration = 0.45,
                        easing = "outback",
                        end_value = 1,
                        key_type = "tween",
                        node_id = "group",
                        property_id = "scale_y",
                        start_time = 0.15,
                        start_value = 1.05,
                    },
                },
                duration = 0.6,
            },
        },
        metadata = {
            fps = 60,
            gizmo_steps = {
            },
            gui_path = "entity/background/background.gui",
            layers = {
            },
            settings = {
                font_size = 40,
            },
            template_animation_paths = {
                background_star_row1 = require("entity.background.background_star_row_panthera"),
                background_star_row2 = require("entity.background.background_star_row_panthera"),
                background_star_row3 = require("entity.background.background_star_row_panthera"),
                background_star_row4 = require("entity.background.background_star_row_panthera"),
            },
        },
        nodes = {
        },
    },
    format = "json",
    type = "animation_editor",
    version = 1,
}