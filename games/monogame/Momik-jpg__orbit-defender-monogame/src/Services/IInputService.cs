using Microsoft.Xna.Framework;

namespace OrbitDefender.Services;

public interface IInputService
{
    Vector2 MovementDirection { get; }
    bool IsShootPressed { get; }
    bool IsPausePressed { get; }
    bool IsStartPressed { get; }
    bool IsRestartPressed { get; }
    bool IsBackPressed { get; }

    void Update();
}
