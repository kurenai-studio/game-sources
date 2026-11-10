using UnityEngine;

public class WallHitParticle : MonoBehaviour {
	public float aliveTime = 0.25f;
	private float aliveTimer;

	void Update() {
		aliveTimer += Time.deltaTime;

		if (aliveTimer > aliveTime) {
			Destroy(gameObject);
		}
	}
}
