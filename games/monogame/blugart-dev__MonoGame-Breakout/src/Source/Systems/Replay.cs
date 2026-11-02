using System.Collections.Generic;

namespace Breakout.Systems;

/// <summary>
/// A finished run, replayable: the session's starting conditions (mode, start
/// level, RNG seed) plus every simulation tick's input. Note what is NOT here
/// — no ball positions, no scores, no events. Replaying re-*simulates*: feed
/// the frames back through the very states that consumed them live, and the
/// fixed timestep plus the seeded Random reproduce everything else. That is
/// why this file is twenty lines and not a serialization of the world.
/// </summary>
public sealed class Replay
{
    public GameMode Mode { get; }
    public int StartLevel { get; }
    public int Seed { get; }
    public List<InputSnapshot> Frames { get; } = new();

    public Replay(GameMode mode, int startLevel, int seed)
    {
        Mode = mode;
        StartLevel = startLevel;
        Seed = seed;
    }
}
