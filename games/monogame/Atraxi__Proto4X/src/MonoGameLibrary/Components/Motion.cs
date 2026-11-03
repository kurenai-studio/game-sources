using Microsoft.Xna.Framework;
using MonoGameLibrary.Components.Infrastructure;
using System;

namespace MonoGameLibrary.Components
{
    public struct Motion(Vector2 velocity,
        Vector2 acceleration = default,
        float angularVelocity = 0,
        float angularAcceleration = 0) : IDependsOnOtherComponents
    {
        public Vector2 Velocity = velocity;
        public Vector2 Acceleration = acceleration;
        public float AngularVelocity = angularVelocity;
        public float AngularAcceleration = angularAcceleration;

        public readonly Type[] GetComponentDependencies => [typeof(Position)];
    }
}
