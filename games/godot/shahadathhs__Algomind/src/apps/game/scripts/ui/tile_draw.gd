class_name TileDraw
extends RefCounted
## One tile of the interface (a tape cell, a stat figure, a letter of the wordmark) in the current
## look: flat is a fill with an ink outline; depth is a key with a lip and a soft shadow.

## PLAIN is an upcoming or idle tile, SOLID one that was run or is selected, ACTIVE the tile the
## read-head is on (and the one that failed, which also carries its own icon).
enum Tone { PLAIN, SOLID, ACTIVE }


## Draws the tile and returns the rect its content belongs in: the same rect when flat, the face
## of the key (without the lip) when depth.
static func tile(canvas: CanvasItem, rect: Rect2, tone: Tone) -> Rect2:
	if UiLook.depth:
		var kind := DepthKit.Kind.TILE
		if tone == Tone.SOLID:
			kind = DepthKit.Kind.INK
		elif tone == Tone.ACTIVE:
			kind = DepthKit.Kind.SIGNAL
		return DepthKit.key(canvas, rect, kind)
	match tone:
		Tone.ACTIVE:
			UiKit.fill_chamfer(canvas, rect, Palette.SIGNAL)
		Tone.SOLID:
			UiKit.fill_chamfer(canvas, rect, Palette.INK)
		_:
			UiKit.fill_chamfer(canvas, rect, Palette.FLOOR)
			UiKit.outline_chamfer(canvas, rect, Palette.INK)
	return rect
