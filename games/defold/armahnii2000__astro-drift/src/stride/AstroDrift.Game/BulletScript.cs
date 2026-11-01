using Stride.Core.Mathematics;
using Stride.Engine;

namespace AstroDrift
{
	public class BulletScript : SyncScript
	{
		public Vector3 Velocity { get; set; } = Vector3.Zero;
		public float Lifetime { get; set; } = 1.0f;
		public float WorldBound { get; set; } = 12f;

		private float _life;

		public override void Start()
		{
			_life = Lifetime;
		}

		public override void Update()
		{
			float dt = (float)Game.UpdateTime.Elapsed.TotalSeconds;
			_life -= dt;
			if (_life <= 0f)
			{
				SceneSystem.SceneInstance.RootScene.Entities.Remove(Entity);
				return;
			}

			var p = Entity.Transform.Position + Velocity * dt;
			if (p.X > WorldBound) p.X = -WorldBound;
			else if (p.X < -WorldBound) p.X = WorldBound;
			if (p.Z > WorldBound) p.Z = -WorldBound;
			else if (p.Z < -WorldBound) p.Z = WorldBound;
			Entity.Transform.Position = p;
		}
	}
}
