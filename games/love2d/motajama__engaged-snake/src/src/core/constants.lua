local Constants = {
    logical_width = 320,
    logical_height = 240,
    internal_scale = 1,
    window_scale = 2,
}

Constants.internal_width = Constants.logical_width * Constants.internal_scale
Constants.internal_height = Constants.logical_height * Constants.internal_scale
Constants.window_width = Constants.internal_width * Constants.window_scale
Constants.window_height = Constants.internal_height * Constants.window_scale

return Constants
