using System;
using Stride.Core.Mathematics;
using Stride.Engine;
using Stride.Input;

namespace AstroDrift
{
	public class PlayerScript : SyncScript
	{
		public float Thrust { get; set; } = 12f;
		public float RotationSpeed { get; set; } = 4f;
		public float Drag { get; set; } = 0.55f;
		public float BrakeDrag { get; set; } = 0.08f;
		public float MaxSpeed { get; set; } = 16f;
		public float WorldBound { get; set; } = 12f;
		public float ShootCooldown { get; set; } = 0.18f;

		public Prefab BulletPrefab { get; set; }

		private Vector3 _velocity = Vector3.Zero;
		private float _heading = 0f;
		private float _cooldown = 0f;

		public override void Update()
		{
			float dt = (float)Game.UpdateTime.Elapsed.TotalSeconds;

			float rotInput = 0f;
			if (Input.IsKeyDown(Keys.Left)) rotInput -= 1f;
			if (Input.IsKeyDown(Keys.Right)) rotInput += 1f;
			_heading += rotInput * RotationSpeed * dt;

			if (Input.IsKeyDown(Keys.Up))
			{
				var forward = ForwardVector();
				_velocity += forward * Thrust * dt;
			}

			float damp = Input.IsKeyDown(Keys.Down) ? BrakeDrag : Drag;
			_velocity *= (float)Math.Pow(damp, dt);
			float speed = _velocity.Length();
			if (speed > MaxSpeed) _velocity = (_velocity / speed) * MaxSpeed;

			var pos = Entity.Transform.Position + _velocity * dt;
			pos = WrapPosition(pos);
			Entity.Transform.Position = pos;
			Entity.Transform.Rotation = Quaternion.RotationY(-_heading);

			_cooldown -= dt;
			if (Input.IsKeyDown(Keys.Delete) && _cooldown <= 0f)
			{
				_cooldown = ShootCooldown;
				SpawnBullet();
			}
		}

		private Vector3 ForwardVector()
		{
			return new Vector3(
				(float)Math.Sin(_heading),
				0f,
				(float)Math.Cos(_heading));
		}

		private Vector3 WrapPosition(Vector3 p)
		{
			if (p.X > WorldBound) p.X = -WorldBound;
			else if (p.X < -WorldBound) p.X = WorldBound;
			if (p.Z > WorldBound) p.Z = -WorldBound;
			else if (p.Z < -WorldBound) p.Z = WorldBound;
			return p;
		}

		private void SpawnBullet()
		{
			if (BulletPrefab == null) return;
			var instances = BulletPrefab.Instantiate();
			var forward = ForwardVector();
			foreach (var instance in instances)
			{
				instance.Transform.Position = Entity.Transform.Position + forward * 0.6f;
				var bullet = instance.Get<BulletScript>();
				if (bullet != null) bullet.Velocity = forward * 24f;
				SceneSystem.SceneInstance.RootScene.Entities.Add(instance);
			}
		}
	}
}
