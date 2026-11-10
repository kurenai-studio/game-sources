using UnityEngine;

public class Pistol : EnemyController {
	public float pistolCooldown = 0.25f;
	private float timer;
	public GameObject bullet;
	public float bulletDistance = 1f;
	private GameObject shotBullet;
	public GameObject hitWallParticle;

	private bool shoot;

	override protected void Init() { }

	override protected void NoticePlayer() { }

	override protected void HitTarget() { }

	override protected void AwayFromTarget() {
		anim.SetBool("Gun", false);
		timer = 0;
	}

	override protected void CloseToTarget() {
		move = Vector3.zero;

		if (target.CompareTag("Player")) {
			anim.SetBool("Gun", true);
			rb.velocity = Vector2.zero;
			timer += Time.deltaTime;
			if (pistolCooldown < timer) {
				anim.SetTrigger("Shoot");
				shoot = true;
				timer = 0;
			}
		}
	}

	override protected void Attack() {
		shoot = true;
		anim.SetTrigger("Shoot");
	}

	protected override void PlayerAvoidedAttack() {
		StartCoroutine(shotBullet.GetComponent<Bullet>().Destroy());
	}

	public void BulletRayCast(Transform bullet) {
		RaycastHit2D hit;
		if (hit = Physics2D.Raycast(bullet.position, bullet.right, Mathf.Infinity, ~((1 << LayerMask.NameToLayer("Ignore Raycast")) | (1 << LayerMask.NameToLayer("UI"))))) {
			ShootBullet(hit);
		}
	}

	public void Shoot() {
		if (Replay.IN_REPLAY) return;

		RaycastHit2D[] hits = new RaycastHit2D[1];
		if (col.Raycast(transform.up, hits, Mathf.Infinity, ~((1 << LayerMask.NameToLayer("Ignore Raycast")) | (1 << LayerMask.NameToLayer("UI")))) != 0) {
			ShootBullet(hits[0]);
		}
	}

	private void ShootBullet(RaycastHit2D hit) {
		if (hit.transform.CompareTag("Player")) {
			PlayerController player;

			if (player = hit.transform.GetComponent<PlayerController>()) {
				player.Kill(gameObject);

				Vector3 toPlayer = transform.position - hit.transform.position;
				shotBullet = Instantiate(bullet, toPlayer.normalized * bulletDistance + hit.transform.position, Quaternion.Euler(0, 0, Mathf.Atan2(toPlayer.y, toPlayer.x) * Mathf.Rad2Deg + 180));
				shotBullet.GetComponent<Bullet>().shooting = transform;
			} else {
				hit.transform.GetComponent<EnemyController>().Kill(transform.up, DeathStyle.SHOT);
			}
		} else if (hit.transform.CompareTag("Enemy")) {
			hit.transform.GetComponent<EnemyController>().Kill(transform.up, DeathStyle.SHOT);
		} else {//Hits wall
			Quaternion rot = Quaternion.LookRotation(hit.normal, Vector3.back);
			Instantiate(hitWallParticle, hit.point, rot);
		}
	}

	protected override void TakenOver() {
		anim.SetBool("Gun", true);
	}

	protected override void TargetDead() {
		anim.SetBool("Gun", false);
	}

	protected override object[] GetAnimationData() {
		bool sht = shoot;
		shoot = false;

		return new object[] { anim.GetBool("Run"), anim.GetBool("Gun"), sht };
	}

	protected override void SetAnimationData(object[] data) {
		anim.SetBool("Run", (bool)data[0]);
		anim.SetBool("Gun", (bool)data[1]);
		if ((bool)data[2]) anim.SetTrigger("Shoot");
	}

	protected override void StopAttack() { }
	protected override void UpdateEnemy() { }
}
