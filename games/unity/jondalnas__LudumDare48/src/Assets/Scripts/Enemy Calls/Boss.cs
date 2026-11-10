using UnityEngine;
using System.Collections;

public class Boss : EnemyController {
	private int hitCount = 0;
	public float playerKnockback;
	public float knockbackTime;
	private float knockbackTimer;
	private float timer;
	private Vector2 chargeDir;
	public float chargeSpeed;
	public float knockedoutTime = 1;
	public float walkingTime = 3;
	public float knockedoutTimer;
	private State state;

	private enum State {
		walking, charging, knockedOut
	}

	void Update() {
		timer += Time.deltaTime;

		if (dead) {
			Camera.main.GetComponent<CameraController>().grainyness = Mathf.Pow(timer / 3f, 10) * 2;

			if (timer > 3) GameLoop.LoadlLevel(5);

			return;
		}

		knockbackTimer += Time.deltaTime;

		Vector3 toPlayer = player.transform.position - transform.position;
		float dist = toPlayer.magnitude;

		if (state == State.walking) {
			Vector3 dir = toPlayer / dist;
			move = dir * speed;

			if ((dist < 3 && timer > walkingTime * 0.25) || timer > walkingTime) {
				state = State.charging;
				chargeDir = dir;
			}
		}

		if (state == State.charging) {
			move = chargeDir * chargeSpeed;
		}

		if (state == State.knockedOut) {
			move = Vector3.zero;

			if (timer > knockedoutTime) {
				state = State.walking;
			}
		}

		if (knockbackTimer > knockbackTime) {
			player.GetComponent<PlayerController>().knockedBack = false;
		}

		Quaternion rot = Quaternion.LookRotation(move, Vector3.back);
		rot.x = 0;
		rot.y = 0;
		transform.rotation = rot;
	}

	void FixedUpdate() {
		rb.velocity = move;
	}

	private void OnCollisionEnter2D(Collision2D collision) {
		if (state == State.charging) {
			state = State.knockedOut;
			timer = 0;
		}

		if (collision.transform.CompareTag("Player")) {
			collision.transform.GetComponent<PlayerController>().Kill(gameObject);
		}
	}

	protected override void Attack() {

	}

	protected override void AwayFromTarget() {

	}

	protected override void CloseToTarget() {
	}

	protected override object[] GetAnimationData() {
		return new object[] { anim.GetBool("Run") };
	}

	protected override void HitTarget() {
	}

	protected override void Init() {
		rb.bodyType = RigidbodyType2D.Dynamic;
	}

	protected override void NoticePlayer() {
	}

	protected override void PlayerAvoidedAttack() {

	}

	protected override void SetAnimationData(object[] data) {
		anim.SetBool("Run", (bool)data[0]);
	}

	protected override void StopAttack() {
	}

	protected override void TakenOver() {
	}

	protected override void UpdateEnemy() {
	}

	public override void Kill(Vector2 dir, DeathStyle style) {
		if (state != State.knockedOut) return;

		if (hitCount == 4) {
			timer = 0;

			player.GetComponent<PlayerController>().knockedBack = false;

			Quaternion rot = Quaternion.LookRotation(player.transform.position - transform.position, Vector3.back);
			rot.x = 0;
			rot.y = 0;
			transform.rotation = rot;

			Kill(DeathStyle.DECAP);

			return;
		}

		hitCount++;
		knockbackTimer = 0;
		player.GetComponent<PlayerController>().knockedBack = true;
		player.GetComponent<Rigidbody2D>().velocity = (player.transform.position - transform.position).normalized * playerKnockback;

		state = State.walking;
		timer = 0;
	}

	protected override void TargetDead() { }
}
