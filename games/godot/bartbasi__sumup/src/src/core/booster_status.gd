class_name BoosterStatus extends RefCounted
## One booster as the interface shows it. GameSession fills it in. It lives in
## core so the design and ui areas depend on core only.

## NO_TARGET (SEC-01): nothing on the board it can act on. Appended last so
## the older values keep their numbers.
enum Usability { USABLE, CANNOT_AFFORD, NO_SNAPSHOT, NO_TARGET }

var id: StringName
var cost: int             # the price as an exponent (the price is 2^cost), free or not (AT-56)
var usable: bool
var reason: Usability
var active: bool          # this booster is in targeting mode
var suggested: bool       # marked as the suggested rescue in the no moves offer (D-42)
var free: bool            # D-46: a free booster is held, so using this booster would charge 0. The bar shows "Free".
