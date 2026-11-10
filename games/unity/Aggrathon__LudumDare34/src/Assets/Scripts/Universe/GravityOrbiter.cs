using UnityEngine;

[RequireComponent(typeof(Rigidbody2D))]
public class GravityOrbiter : GravityObject
{
	public Rigidbody2D orbitAround;
	public bool switchDirection;

	void Start()
	{
		Rigidbody2D rig = GetComponent<Rigidbody2D>();
		rig.velocity = PhysicsFunctions.OrbitalSpeed(rig, orbitAround, switchDirection);
	}
}
