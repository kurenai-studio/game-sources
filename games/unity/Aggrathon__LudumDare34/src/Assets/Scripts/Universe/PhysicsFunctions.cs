using UnityEngine;

public static class PhysicsFunctions
{
	public static float GRAVITY_CONSTANT = 4* 6.67408E-3f; //REAL: 6.67408E-11f



	public static Vector2 GravityForce(Rigidbody2D rig1, Rigidbody2D rig2)
	{
		Vector2 dir = rig1.position - rig2.position;
		float magnitude = (rig1.mass * rig2.mass / dir.sqrMagnitude * GRAVITY_CONSTANT) / dir.magnitude;
		return new Vector2(dir.x * magnitude, dir.y * magnitude);
	}

	public static Vector2 OrbitalSpeed(Rigidbody2D orbiter, Rigidbody2D center, bool switchDirection = false)
	{
		return OrbitalSpeed(center.position - orbiter.position, center.mass, switchDirection);
	}

	public static Vector2 OrbitalSpeed(Vector2 CenterDistance, float centerMass, bool switchDirection = false)
	{
		float velocity = Mathf.Sqrt(GRAVITY_CONSTANT * centerMass / CenterDistance.magnitude);
		if (switchDirection)
			velocity = -velocity;
		CenterDistance = new Vector2(1, -CenterDistance.x / CenterDistance.y);
		return CenterDistance * (velocity / CenterDistance.magnitude);
	}

	public static void RigidBodyFollow(Rigidbody2D rig, Vector2 target, float acc, float turn, float angleLimit)
	{
		Vector2 dir = rig.transform.InverseTransformPoint(target);
		float angle = Mathf.Atan2(dir.x, dir.y);
		if (angle > angleLimit || angle < -angleLimit)
		{
			rig.AddTorque((angle < 0 ? turn : -turn) * Time.fixedDeltaTime);
        }
		else
		{
			float torque = - turn * angle/angleLimit;
			if(angle*rig.angularVelocity > 1)
			{
				if (rig.angularVelocity > angleLimit)
				{
					torque -= turn*0.5f;
				}
				else if(rig.angularVelocity < -angleLimit)
				{
					torque += turn*0.5f;
				}
			}
			rig.AddForce(rig.transform.up * acc * Time.fixedDeltaTime);
			rig.AddTorque(torque*Time.fixedDeltaTime);
		}
	}
}
