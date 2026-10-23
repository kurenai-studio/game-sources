return {
    data = {
        animations = {
            {
                animation_id = "on_hit",
                animation_keys = {
                    {
                        duration = 0.07,
                        easing = "outsine",
                        end_value = -3,
                        key_type = "tween",
                        node_id = "body",
                        property_id = "position_x",
                        start_time = 0.1,
                    },
                    {
                        duration = 0.07,
                        easing = "outsine",
                        end_value = 3,
                        key_type = "tween",
                        node_id = "body",
                        property_id = "position_y",
                        start_time = 0.1,
                    },
                    {
                        duration = 0.45,
                        easing = "outelastic",
                        key_type = "tween",
                        node_id = "body",
                        property_id = "position_x",
                        start_time = 0.17,
                        start_value = -3,
                    },
                    {
                        duration = 0.45,
                        easing = "outelastic",
                        key_type = "tween",
                        node_id = "body",
                        property_id = "position_y",
                        start_time = 0.17,
                        start_value = 3,
                    },
                },
                duration = 0.8,
            },
        },
        metadata = {
            fps = 60,
            gizmo_steps = {
            },
            gui_path = "entity/tile_wall/tile_wall.collection",
            layers = {
            },
            settings = {
                font_size = 40,
            },
            template_animation_paths = {
            },
        },
        nodes = {
        },
    },
    format = "json",
    type = "animation_editor",
    version = 1,
}