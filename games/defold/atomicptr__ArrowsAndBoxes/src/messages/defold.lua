return {
    -- Built-in system messages.
    exit = hash "exit",
    reboot = hash "reboot",
    set_update_frequency = hash "set_update_frequency",
    start_record = hash "start_record",
    stop_record = hash "stop_record",
    toggle_profile = hash "toggle_profile",

    -- Built-in game object messages.
    go = {
        acquire_input_focus = hash "acquire_input_focus",
        disable = hash "disable",
        enable = hash "enable",
        release_input_focus = hash "release_input_focus",
        set_parent = hash "set_parent",
    },

    -- Built-in render messages.
    render = {
        clear_color = hash "clear_color",
        draw_line = hash "draw_line",
        draw_text = hash "draw_text",
        window_resized = hash "window_resized",
    },

    -- Built-in sprite messages.
    sprite = {
        animation_done = hash "animation_done",
        play_animation = hash "play_animation",
    },

    -- Built-in sound messages.
    sound = {
        play_sound = hash "play_sound",
        set_gain = hash "set_gain",
        stop_sound = hash "stop_sound",
    },

    -- Built-in spine messages.
    spine = {
        spine_animation_done = hash "spine_animation_done",
        spine_event = hash "spine_event",
    },

    -- Built-in collision messages.
    physics = {
        apply_force = hash "apply_force",
        collision_response = hash "collision_response",
        contact_point_response = hash "contact_point_response",
        ray_cast_response = hash "ray_cast_response",
        trigger_response = hash "trigger_response",
    },

    -- Built-in collection proxy messages.
    collectionproxy = {
        async_load = hash "async_load",
        disable = hash "disable",
        enable = hash "enable",
        final = hash "final",
        init = hash "init",
        load = hash "load",
        proxy_loaded = hash "proxy_loaded",
        proxy_unloaded = hash "proxy_unloaded",
        set_time_step = hash "set_time_step",
        unload = hash "unload",
    },

    -- Built-in camera messages.
    camera = {
        acquire_camera_focus = hash "acquire_camera_focus",
        release_camera_focus = hash "release_camera_focus",
        set_camera = hash "set_camera",
    },
}
