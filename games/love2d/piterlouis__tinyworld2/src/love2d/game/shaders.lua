--
-- TinyWorld
--
-- Copyright (c) 2025 piterlouis
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local M = {}

M.motionTrail = love.graphics.newShader[[
  // extern number radius;
  vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _)
  {
    vec4 pixel = Texel(texture, tc);
    vec4 fadeout = vec4(1.0, 1.0, 1.0, 0.99);
    vec4 final = pixel * fadeout;
    if (final.a < 0.1) {
      return vec4(0, 0, 0, 0);
    }
    return final * color;
  }
]]

M.glow = love.graphics.newShader[[
  extern vec2 size = vec2(800, 800);
  extern int samples = 5; // pixels per axis; higher = bigger glow, worse performance
  extern float quality = 2.5; // lower = smaller glow, better quality

  vec4 effect(vec4 colour, Image tex, vec2 tc, vec2 sc)
  {
    vec4 source = Texel(tex, tc);
    vec4 sum = vec4(0);
    int diff = (samples - 1) / 2;
    vec2 sizeFactor = vec2(1) / size * quality;

    for (int x = -diff; x <= diff; x++)
    {
      for (int y = -diff; y <= diff; y++)
      {
        vec2 offset = vec2(x, y) * sizeFactor;
        sum += Texel(tex, tc + offset);
      }
    }

    return ((sum / (samples * samples)) + source) * colour;
  }
]]

M.boxBlur = love.graphics.newShader[[
  extern number radius;
  extern vec2 texSize;

  vec4 effect(vec4 color, Image texture, vec2 texCoords, vec2 screenCoords)
  {
      vec2 pixelSize = 1.0 / texSize;

      vec4 sum = vec4(0.0);
      int count = 0;

      for (int y = -int(radius); y <= int(radius); y++) {
          for (int x = -int(radius); x <= int(radius); x++) {
              vec2 offset = vec2(x, y) * pixelSize;
              sum += Texel(texture, texCoords + offset);
              count += 1;
          }
      }

      return color * (sum / float(count));
  }
]]

return M
