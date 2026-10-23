# Piece Shapes and Color Encoding

The recorded comparison between runtime shapes and the independent table.

This record is a descriptive bounded mapping of runtime shapes to the independent table for PCE-2 and the geometry dependencies of PCE-6. It is not a wall-kick, good-payload, historical-writer, finding-classification or phase-closure record.

## Expected geometry versus extracted definitions

The held V40 method compares raw runtime rotation matrices from the pinned factory to the separate frozen table. Expected kind labels come from table headers, not factory order or parser acceptance. It compares ordered cell lists and box dimensions without reflection, translation normalization or anchor removal. A second check records unordered state-set equality. The O reference has four identical table rows. The one-state rule uses the first row rather than inferring non-rotation from identical pictures.

The held classifier result reports seven distinct concrete tokens, each matching exactly one reference kind. All ordered states and unordered sets match. There are 25 runtime orientations: four each for I, T, S, Z, J and L, and one for O. Box sizes are 4x4 for I, 2x2 for O and 3x3 for the others.

| Kind | Concrete token | Runtime / table orientations |
| --- | --- | --- |
| I | #00C0E8 | 4 / 4 |
| O | #FFCC00 | 1 / 4 identical rows |
| T | #AF52DE | 4 / 4 |
| S | #34C759 | 4 / 4 |
| Z | #FF3B30 | 4 / 4 |
| J | #007AFF | 4 / 4 |
| L | #FF9500 | 4 / 4 |

This table describes the inspected current encoding. REQUIREMENTS PCE-2 requires fixed colors but supplies no external canonical hex list. The seven frozen PieceColors values are distinct; matching geometry identifies their kind association, not normative "usual" colors, case aliases, saved-piece validity or complete good content.

## Separate image/table relation

An attributed held pack-only comparison reports 28/28 image/table states equal. Its final method counts a cell when at least half of its 16x16 block has the piece color, excluding pivot-marker and background pixels. O uses the 2x2 occupied-cell bounding box under B2's box prose, not the larger padded image canvas. A first single-pixel pass produced false mismatches and was corrected; the final result must not be presented as that first pass.

That record compares the two geometry inputs only. It supplies no production comparison, wall-kick verification, original-host authenticity or proof of owner adoption. V40 supplies the separate table/production-definition relation. This preparation inspected the held records and source continuity. It was not a fresh image analysis or new runtime execution.

## Evidence identity and source continuity

Held V40 classifier result SHA-256 `a4c3c0e1f5de15977d0f01060bdc24b8e263eb19b9411cf3cf3c55a0324fe26e`; raw extracted definitions SHA-256 `e037164b951d677f0eb27d39eef43b39b69501ede0172bfdd11d33d27370dd03`. These identify private receipts; they do not publish their contents. The attributed V40 comparison review reports a classifier result reproduced identically from the raw definitions and table; its independent raw extraction differed in runtime-version metadata. That is bounded method fidelity, not a fresh run at the current commit.

At main, public/game/tetrominoFactory.js SHA-256 is `25e1da6c0b1992b0317aef7025fb7030803a8fd20e649a45eb2ddeaa166ae8b4`, matching the receipt's factory identity. Source call anchors: PieceColors 12-20, rotation construction 50-58 and allPieces 61-71. The retained table SHA-256 is `c733639052686c488d7ed156720469a40f17963e893790ab727e9442ac7c524c`; retained image SHA-256 is `5a5c49e378cf00a2632a4cd3b5af36d3831dbbdcc64f8d7b09b93c2353821236`. These match held identities. Source continuity does not establish historical writer behavior, imported payload validity, pivot semantics beyond listed geometry or whole-claim compliance.
