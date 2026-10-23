return {
    data = {
        animations = {
            {
                animation_id = "current",
                animation_keys = {
                    {
                        duration = 0.31,
                        easing = "outquad",
                        end_value = 1.33,
                        key_type = "tween",
                        node_id = "root",
                        property_id = "scale_x",
                        start_value = 1,
                    },
                    {
                        duration = 0.4,
                        easing = "outsine",
                        end_value = 1,
                        key_type = "tween",
                        node_id = "dot",
                        property_id = "color_a",
                        start_value = 1,
                    },
                    {
                        duration = 0.4,
                        easing = "outback",
                        end_value = 1.33,
                        key_type = "tween",
                        node_id = "root",
                        property_id = "scale_y",
                        start_value = 1,
                    },
                },
                duration = 0.4,
            },
            {
                animation_id = "locked",
                animation_keys = {
                    {
                        duration = 0.45,
                        easing = "outback",
                        end_value = 1,
                        key_type = "tween",
                        node_id = "root",
                        property_id = "scale_y",
                        start_value = 1,
                    },
                    {
                        duration = 0.6,
                        easing = "outsine",
                        end_value = 0.4,
                        key_type = "tween",
                        node_id = "dot",
                        property_id = "color_a",
                        start_value = 1,
                    },
                    {
                        duration = 0.6,
                        easing = "outback",
                        end_value = 1,
                        key_type = "tween",
                        node_id = "root",
                        property_id = "scale_x",
                        start_value = 1,
                    },
                },
                duration = 0.6,
            },
            {
                animation_id = "completed",
                animation_keys = {
                    {
                        duration = 0.3,
                        easing = "outsine",
                        end_value = 1,
                        key_type = "tween",
                        node_id = "dot",
                        property_id = "color_a",
                        start_value = 1,
                    },
                    {
                        duration = 0.3,
                        easing = "outback",
                        end_value = 1,
                        key_type = "tween",
                        node_id = "root",
                        property_id = "scale_x",
                        start_value = 1,
                    },
                    {
                        duration = 0.3,
                        easing = "outback",
                        end_value = 1,
                        key_type = "tween",
                        node_id = "root",
                        property_id = "scale_y",
                        start_value = 1,
                    },
                },
                duration = 0.3,
            },
        },
        metadata = {
            fps = 60,
            gizmo_steps = {
            },
            gui_path = "widget/fill_dots/fill_dot.gui",
            layers = {
                {
                    color = "73E84C",
                    name = "gui",
                },
                {
                    color = "90D2F6",
                    name = "text",
                },
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