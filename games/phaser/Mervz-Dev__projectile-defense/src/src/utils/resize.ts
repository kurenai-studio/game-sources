import { BASE_HEIGHT, BASE_WIDTH } from "../constants/dimensions";

export function getScreenSizeRatio(
  maxWidth = BASE_WIDTH,
  maxHeight = BASE_HEIGHT
) {
  const w = window.innerWidth;
  const h = window.innerHeight;

  // Detect mobile devices
  const isMobile =
    /Android|iPhone|iPad|iPod|Opera Mini|IEMobile|WPDesktop/i.test(
      navigator.userAgent
    );

  let finalWidth: number;
  let finalHeight: number;

  if (isMobile) {
    // On mobile, just use the device width and height
    finalWidth = w;
    finalHeight = h;
  } else {
    // compute width based on height
    const heightBasedWidth = h * (16 / 9);

    // compute height based on width
    const widthBasedHeight = w * (9 / 16);

    if (heightBasedWidth <= w) {
      // height is the limiting factor
      finalWidth = heightBasedWidth;
      finalHeight = h;
    } else {
      // width is the limiting factor
      finalWidth = w;
      finalHeight = widthBasedHeight;
    }

    // apply maximum constraints
    if (finalWidth > maxWidth) {
      finalWidth = maxWidth;
      finalHeight = maxWidth * (9 / 16);
    }

    if (finalHeight > maxHeight) {
      finalHeight = maxHeight;
      finalWidth = maxHeight * (16 / 9);
    }
  }

  return { width: finalWidth, height: finalHeight };
}
