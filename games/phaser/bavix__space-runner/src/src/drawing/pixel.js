// Pixel drawing utility
export function drawPixel(graphics, x, y, size = 1) {
  graphics.fillRect(Math.floor(x), Math.floor(y), size, size);
}






