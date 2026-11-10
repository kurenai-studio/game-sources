using UnityEngine;

public class Scythe : MonoBehaviour {
	public float spinSpeed = 360 * 4;
	public float speed = 10;
	public float returnSpeed = 30;
	[HideInInspector]
	public Vector3 dir;
	private Transform player;

	private Collider2D col;
	private ContactFilter2D hitContactFilter;
	private bool returning;
	private float lastDist;

	public float maxDistFromPlayer = 10;

	private void Start() {
		col = GetComponent<Collider2D>();

		hitContactFilter = new ContactFilter2D {
			useLayerMask = true,
			layerMask = LayerMask.GetMask("Enemy") | LayerMask.GetMask("Level") | LayerMask.GetMask("Default") | LayerMask.GetMask("Ignore Raycast") | LayerMask.GetMask("Boss")
		};

		player = GameObject.Find("Player").transform;
	}

	void FixedUpdate() {
		if (Replay.IN_REPLAY) return;

		if (dir == Vector3.zero) Debug.LogError("Direction has not been initialized or it has been initialized to zero");

		//Move and rotate
		transform.position += dir * speed * Time.fixedDeltaTime;
		transform.Rotate(0, 0, spinSpeed * Time.fixedDeltaTime);

		//Collision
		Collider2D[] cols = new Collider2D[1];
		if (col.OverlapCollider(hitContactFilter, cols) != 0) {
			if (cols[0].CompareTag("Enemy")) {
				cols[0].GetComponent<EnemyController>().Kill(cols[0].transform.position - transform.position, EnemyController.DeathStyle.DECAP);

				if (cols[0].GetComponent<Boss>()) {
					Return();
				}
			} else {
				Return();
			}
		}

		//Return if too far away
		Vector3 toPlayer = player.position - transform.position;
		float dist = toPlayer.magnitude;
		if (dist > maxDistFromPlayer) {
			Return();
		}

		//Return
		if (returning) {
			dir = toPlayer / dist;

			if (dist < 0.5f) {
				player.GetComponent<PlayerController>().ScytheReturned();
				Destroy(gameObject);
			}
		}

		lastDist = dist;
	}

	private void Return() {
		returning = true;
		speed = returnSpeed;
		spinSpeed = 0;
	}
}
