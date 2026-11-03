// Copied from F:\bay-ride\src\platform.ts (Bay Ride), probeGpu() only.

/** What the GPU can render to: half-float colour targets, and how many MSAA samples each format takes. */
export interface GpuCaps {
  halfFloat: boolean;
  samplesHalf: number;
  samples8: number;
  maxTexture: number;
}

/**
 * Probe once on the game's own context. Half-float colour targets need EXT_color_buffer_float (or
 * _half_float). Without them every float target falls back to 8 bits instead of an incomplete
 * framebuffer and a black screen. `?nofloat=1` forces the fallback for testing.
 */
export function probeGpu(gl: WebGL2RenderingContext): GpuCaps {
  const params = new URLSearchParams(location.search);
  const ext = !!(gl.getExtension("EXT_color_buffer_float") || gl.getExtension("EXT_color_buffer_half_float"));
  let halfFloat = false;
  if (ext && params.get("nofloat") !== "1") {
    const tex = gl.createTexture(), fb = gl.createFramebuffer();
    const prevFb = gl.getParameter(gl.FRAMEBUFFER_BINDING), prevTex = gl.getParameter(gl.TEXTURE_BINDING_2D);
    gl.bindTexture(gl.TEXTURE_2D, tex);
    gl.texStorage2D(gl.TEXTURE_2D, 1, gl.RGBA16F, 4, 4);
    gl.bindFramebuffer(gl.FRAMEBUFFER, fb);
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, tex, 0);
    halfFloat = gl.checkFramebufferStatus(gl.FRAMEBUFFER) === gl.FRAMEBUFFER_COMPLETE;
    gl.bindFramebuffer(gl.FRAMEBUFFER, prevFb);
    gl.bindTexture(gl.TEXTURE_2D, prevTex);
    gl.deleteFramebuffer(fb);
    gl.deleteTexture(tex);
  }
  const most = (fmt: number) => {
    try {
      const s = gl.getInternalformatParameter(gl.RENDERBUFFER, fmt, gl.SAMPLES) as Int32Array | null;
      return s && s.length ? Math.max(...s) : 0;
    } catch {
      return 0;
    }
  };
  return {
    halfFloat,
    samplesHalf: halfFloat ? most(gl.RGBA16F) : 0,
    samples8: most(gl.RGBA8),
    maxTexture: gl.getParameter(gl.MAX_TEXTURE_SIZE) as number,
  };
}
