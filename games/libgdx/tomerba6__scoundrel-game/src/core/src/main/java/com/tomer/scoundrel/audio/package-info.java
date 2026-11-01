/**
 * The audio's decisions: what each moment sounds like, when the music changes,
 * and how loud it all is.
 *
 * <p>Nothing here plays a sound. {@link com.tomer.scoundrel.audio.SfxChoice}
 * turns the engine's events into {@link com.tomer.scoundrel.audio.Sfx} choices
 * (which file, pitch and volume). {@link com.tomer.scoundrel.audio.PendingCues}
 * holds each one until its animation's beat.
 * {@link com.tomer.scoundrel.audio.MusicDirector} answers, each frame, how loud
 * each track should be and which cue to start.
 * {@link com.tomer.scoundrel.audio.AudioControls} keeps the player's levels and
 * saves them to {@code ~/.scoundrel/audio.settings}. The screens own the actual
 * playback, and they are the only audio code that touches LibGDX.
 *
 * <p>{@link com.tomer.scoundrel.audio.Sound} and
 * {@link com.tomer.scoundrel.audio.StreamFile} are the file contract with the
 * renderer in {@code audio-source/}: every name they expect must exist under
 * {@code assets/audio/}, and a test holds the two to each other.
 *
 * <p>Pure Java with no LibGDX, and gated by the coverage check. It reads the
 * engine's events from outside: {@code model} and {@code rules} never import
 * it. The whole design, from each sound to the mix, is in {@code docs/audio.md}.
 */
package com.tomer.scoundrel.audio;
