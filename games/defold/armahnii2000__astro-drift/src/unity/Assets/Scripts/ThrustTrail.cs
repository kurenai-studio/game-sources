using UnityEngine;

namespace AstroDrift
{
	// Attach to the Player GameObject alongside PlayerController. Drives a
	// ParticleSystem's emission rate from the input axis so the engine trail
	// pulses with thrust. Set the ParticleSystem reference in the inspector;
	// the system itself is authored as a child GO in the editor.
	[RequireComponent(typeof(PlayerController))]
	public class ThrustTrail : MonoBehaviour
	{
		public ParticleSystem thrustParticles;
		public float maxEmissionRate = 120f;

		void Update()
		{
			if (thrustParticles == null) return;
			bool thrusting = Input.GetKey(KeyCode.UpArrow);
			var emission = thrustParticles.emission;
			emission.rateOverTime = thrusting ? maxEmissionRate : 0f;
		}
	}
}
