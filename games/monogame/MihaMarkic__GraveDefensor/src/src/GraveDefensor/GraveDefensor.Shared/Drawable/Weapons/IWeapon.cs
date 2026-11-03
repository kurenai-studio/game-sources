using GraveDefensor.Shared.Services.Implementation;
using Microsoft.Xna.Framework;
using System;

namespace GraveDefensor.Shared.Drawable.Weapons
{
    public interface IWeapon : IClickableDrawable
    {
        Vector2 Center { get; }
        void Update(UpdateContext context, IEnemyWave enemyWave);
    }
}
