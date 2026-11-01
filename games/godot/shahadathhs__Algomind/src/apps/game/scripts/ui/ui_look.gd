class_name UiLook
extends RefCounted
## Which look the interface is drawn in. Set by AppState when the theme or the Look setting is
## applied; the pieces that differ in shape between the looks read it when they draw.

static var depth := false
## False when the player chose reduce motion: pieces then change state without easing.
static var animate := true
