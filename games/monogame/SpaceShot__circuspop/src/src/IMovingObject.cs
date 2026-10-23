using Microsoft.Xna.Framework;

namespace CircusPop;

interface IMovingObject
{
    Vector2 Position { get; }
    Vector2 Velocity { get; }
}
