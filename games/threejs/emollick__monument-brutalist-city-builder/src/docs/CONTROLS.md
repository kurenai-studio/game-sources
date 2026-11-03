# Controls

Monument supports mouse, keyboard, trackpad, and touch. Desktop and mobile expose the same architectural capabilities, but mobile separates direct manipulation from the detailed inspector to preserve the city view.

## Starting and navigating

- Choose **Open Ground** for a blank site or open one of the three ready cities.
- Use **Menu** to save the current city and return to the starting screen.
- Use **City Library** to name, save, reopen, or remove local cities.
- Use **Focus** to hide editing chrome while retaining time, camera, pause, and save controls.

## Selecting buildings

### Desktop

Click a building to:

- Focus the camera on it.
- Show its colored 3D manipulation handles.
- Open the full design inspector.

Close the inspector or click empty ground to finish editing.

### Mobile

Tap a building to enter **Direct Edit**:

- The camera switches to a focused orbit view.
- The full handle set remains visible.
- The objective, lens, mood, and time rails temporarily hide.
- **Design** opens the full building inspector.
- Closing the inspector returns to Direct Edit rather than deselecting.
- **Done** finishes editing and restores the city controls.

Pinch to zoom and drag empty space to orbit. Drag a colored handle to change the building.

Public spaces have no 3D massing gizmo, so their inspector opens immediately on both desktop and mobile.

## Direct manipulation handles

The visible handle set depends on the building's composition and profile.

| Handle | Effect |
| --- | --- |
| Move | Relocates the building across the parcel grid |
| Height | Changes total height and generated levels |
| Span | Changes building width and structural bays |
| Depth | Changes the occupied depth and floorplate |
| Cantilever | Extends supported upper masses where the grammar permits |
| Void | Carves or enlarges openings in compatible compositions |
| Taper | Changes the vertical profile; capsule taper changes pod spread and spine expression |
| Break | Separates or articulates compatible masses |
| Repeat | Changes module density, tiers, ring segments, frames, or capsule counts |
| Branch | Adds lateral growth where the composition supports it |
| Crown | Intensifies the roof termination or upper structure |
| Rotation | Rotates the building around its site |

Dragging follows the colored world-space rail, not raw horizontal screen movement. Hold `Shift` for precision. Focus a handle and use the arrow keys for stepped keyboard changes.

If a control cannot affect the active architectural grammar, it is disabled in the inspector with an explanation. Some values remain active for analysis even when the current facade does not display them directly.

## Building inspector

The inspector is divided into four areas:

- **Massing**: composition, growth profile, site extent, architectural trajectory, repetition, articulation, branches, and crown.
- **Envelope**: language, material, facade, porosity, facade depth, balconies, vegetation, and weathering.
- **Use**: residential, studio, institutional, gallery/event, or hybrid program.
- **Analysis**: geometry, floor area, carbon, energy, daylight, shade, public interface, and resilience feedback.

**Grow Sibling** finds a clear nearby site and creates a related variation. **Remove** deconstructs the selected object.

## Building and public-space tools

| Key | Tool |
| --- | --- |
| `V` | Select |
| `1` | Residential building |
| `2` | Studio / workplace |
| `3` | Institution |
| `4` | Gallery / event building |
| `5` | Hybrid building |
| `6` | Public realm |
| `X` | Demolish |

Choose a building tool, then choose an empty parcel. New buildings enter the same focused editing flow as an existing selection.

## Camera

- **Orbit**: drag to rotate, right-drag to pan, and scroll or pinch to zoom.
- **Street**: low camera for walking-scale views. Use `W`, `A`, `S`, and `D` to translate when a keyboard is available.
- **Aerial**: overhead district view.
- **Cinematic**: automatic orbiting survey.

Selecting the active camera again refocuses it. On compact mobile layouts, the camera button cycles through the modes.

## Lenses

- **Material**: concrete color, weathering, planting, and facade expression.
- **Program**: color-coded use.
- **Structure**: transparent shell with slabs, columns, cores, and load paths.
- **Daylight**: relative solar access.
- **Activity**: occupied and public-life intensity.
- **Embodied C**: relative embodied-carbon impact.

Lenses do not change the saved architecture; they change how it is inspected.

## Moods

- **Default**: warm concrete, civic light, and neutral streets.
- **Cyberpunk**: dark infrastructure, non-English/glyph signage, neon accents, dense service detail, and stronger bloom.
- **Green**: planted roofs, brighter landscape, ecological street details, and a greener grade.
- **Totalitarian**: severe underlighting, searchlights, banners, checkpoints, and colder monumental space.
- **University**: warmer academic streets, campus detail, civic signage, and evening activity.

Choosing a mood also moves the default time to a representative hour. You can then adjust time manually.

## Time and city life

- Play/pause controls the day/night clock and traffic motion.
- Select `1×`, `3×`, or fast time.
- Drag the time slider to inspect a particular hour.
- Building occupancy, window light, people, and some district details respond to time and growth choices.

## Keyboard shortcuts

| Shortcut | Action |
| --- | --- |
| `Space` | Play or pause |
| `F` | Enter or leave Focus mode |
| `?` | Open the field manual |
| `Ctrl/Cmd+Z` | Undo |
| `Escape` | Close the current mobile inspector/panel, leave selection, or exit Focus mode |

## Accessibility notes

- Interactive controls expose accessible names and visible keyboard focus.
- Direct handles use slider/button semantics and support keyboard operation.
- Coarse pointers receive larger targets and range thumbs.
- Reduced-motion preferences disable nonessential loading animation.
- Analytical information is not conveyed by color alone; labels and legends accompany lenses and programs.
