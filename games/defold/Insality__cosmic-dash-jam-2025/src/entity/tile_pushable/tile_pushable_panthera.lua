return {
    data = {
        animations = {
            {
                animation_id = "default",
                animation_keys = {
                },
                duration = 1,
            },
            {
                animation_id = "on_hit",
                animation_keys = {
                    {
                        duration = 0.047,
                        easing = "outsine",
                        end_value = 0.95,
                        key_type = "tween",
                        node_id = "body",
                        property_id = "scale_x",
                        start_time = 0.097,
                        start_value = 1,
                    },
                    {
                        duration = 0.047,
                        easing = "outsine",
                        end_value = 1.11,
                        key_type = "tween",
                        node_id = "body",
                        property_id = "scale_y",
                        start_time = 0.097,
                        start_value = 1,
                    },
                    {
                        duration = 0.236,
                        easing = "insine",
                        end_value = 1,
                        key_type = "tween",
                        node_id = "body",
                        property_id = "scale_x",
                        start_time = 0.144,
                        start_value = 0.95,
                    },
                    {
                        duration = 0.236,
                        easing = "insine",
                        end_value = 1,
                        key_type = "tween",
                        node_id = "body",
                        property_id = "scale_y",
                        start_time = 0.144,
                        start_value = 1.11,
                    },
                },
                duration = 0.55,
            },
        },
        metadata = {
            fps = 60,
            gizmo_steps = {
            },
            gui_path = "entity/tile_pushable/tile_pushable.collection",
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