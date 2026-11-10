using UnityEngine;

public class Brawler : EnemyController {
	protected bool attacking;
	protected Collider2D hitCol;

	private ContactFilter2D contactFilter;

	override protected void Init() {
		hitCol = transform.Find("Hit collider").GetComponent<Collider2D>();

		contactFilter = new ContactFilter2D {
			useLayerMask = true,
			layerMask = LayerMask.GetMask(new string[] { "Enemy" })
		};
	}

	protected override void UpdateEnemy() {
		if (!attacking) return;

		Collider2D[] cols = new Collider2D[1];
		if (hitCol.OverlapCollider(contactFilter, cols) != 0) {
			cols[0].GetComponent<EnemyController>().Kill(cols[0].transform.position - transform.position, DeathStyle.SHOT);
		}
	}

	override protected void NoticePlayer() { }

	override protected void HitTarget() {
		if (target == player.transform) {
			player.GetComponent<PlayerController>().Kill(gameObject);
			rb.velocity = Vector2.zero;
		} else if (target.CompareTag("Player")) { //Must be player controlled enemy
			target.GetComponent<EnemyController>().Kill(transform.position - target.position, DeathStyle.SHOT);
		}
	}

	override protected void AwayFromTarget() {
		anim.SetBool("Punch", false);
	}
	override protected void CloseToTarget() {
		anim.SetBool("Punch", true);
		Vector3 move = target.transform.position - transform.position;
		float dist = move.magnitude;
		if (dist < minDist) {
			HitTarget();
		} else {
			anim.SetBool("Run", true);
		}
	}

	protected override void Attack() {
		attacking = true;

		anim.SetBool("Punch", true);
	}

	protected override void StopAttack() {
		attacking = false;

		anim.SetBool("Punch", false);
	}

	protected override void TargetDead() {
		anim.SetBool("Punch", false);
	}

	protected override object[] GetAnimationData() {
		return new object[] { anim.GetBool("Punch"), anim.GetBool("Run") };
	}

	protected override void SetAnimationData(object[] data) {
		anim.SetBool("Punch", (bool)data[0]);
		anim.SetBool("Run", (bool)data[1]);
	}

	protected override void TakenOver() { }

	protected override void PlayerAvoidedAttack() { }
}
