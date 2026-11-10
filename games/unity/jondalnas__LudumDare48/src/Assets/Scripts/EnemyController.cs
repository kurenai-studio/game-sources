using UnityEngine;
using System.Collections;
using UnityEngine.Events;
using System;

public abstract class EnemyController : MonoBehaviour, IReplayable {
	protected GameObject player;

	private ParticleSystem blood;
	private ParticleSystem insideBlood;
	private Transform bloodTransform;
	protected bool dead;
	private bool lastDead;
	private DeathStyle style;
	private bool inside;
	private Vector3 killDir;
	public Sprite shotSprite;
	public Sprite decapSprite;
	private SpriteRenderer sr;
	protected Vector2 move;
	private Vector2 playerVel;
	public Transform[] patrolPoints;
	protected int targetCount;
	private int patrolDir = -1;
	private Sprite defaultSprite;

	public enum DeathStyle {
		DECAP,
		SHOT,
		EXPLOSION
	}

	protected Rigidbody2D rb;
	public float speed;
	public float patrolSpeed;
	private bool playerNoticed;
	protected Animator anim;
	protected Transform target;
	protected bool hasTarget;
	public float minDist = 0.5f;
	public float closeDist = 3f;

	protected Collider2D col;

	protected bool beingControlled;
	protected bool firstFrame;

	private Detail detail;

	private bool isAwake;

	// Start is called before the first frame update
	void Start() {
		bloodTransform = transform.Find("Blood");
		blood = bloodTransform.GetComponent<ParticleSystem>();
		insideBlood = transform.Find("Inside Blood").GetComponent<ParticleSystem>();
		blood.Stop();
		insideBlood.Stop();

		sr = GetComponentInChildren<SpriteRenderer>();
		defaultSprite = sr.sprite;

		rb = GetComponent<Rigidbody2D>();
		anim = GetComponent<Animator>();

		player = GameObject.FindWithTag("Player");

		col = GetComponent<Collider2D>();

		detail = GameObject.Find("Detail").GetComponent<Detail>();

		hasTarget = patrolPoints.Length != 0;
		if (hasTarget) {
			target = patrolPoints[0];
		} else {
			rb.bodyType = RigidbodyType2D.Static;
		}

		Init();
	}

	bool lastTarget = false;
	private void FixedUpdate() {
		if (Replay.IN_REPLAY) return;

		if (hasTarget && !lastTarget) {
			rb.bodyType = RigidbodyType2D.Dynamic;
		}
		lastTarget = hasTarget;

		if (beingControlled) {
			rb.velocity = playerVel;
		} else if (hasTarget) {
			if (!target.CompareTag("Player")) {
				rb.velocity = move * patrolSpeed;
			} else {
				rb.velocity = move * speed;
			}
		}
	}

	// Update is called once per frame
	void Update() {
		if (Replay.IN_REPLAY) return;

		if (dead) return;

		UpdateEnemy();

		if (beingControlled) {
			//Look at mouse
			Vector3 mouseWorldPos = Camera.main.ScreenToWorldPoint(Input.mousePosition);

			Vector3 toMouse = mouseWorldPos - transform.position;

			Quaternion rot = Quaternion.LookRotation(toMouse, Vector3.back);
			rot.x = 0;
			rot.y = 0;
			transform.rotation = rot;

			//Player movement
			playerVel = (Input.GetAxis("Horizontal") * Vector2.right + Input.GetAxis("Vertical") * Vector2.up) * speed;
			if (rb.velocity.sqrMagnitude < 0.001) {
				anim.SetBool("Run", false);
			} else {
				anim.SetBool("Run", true);
			}

			//Attack
			if (Input.GetButtonDown("Attack")) {
				Attack();
			} else if (Input.GetButtonUp("Attack")) {
				StopAttack();
			}

			//Exit body
			if (Input.GetButtonDown("Enemy Control") && !firstFrame) {
				KillInside(DeathStyle.EXPLOSION);
			}

			firstFrame = false;

			return;
		}

		if (hasTarget) {
			EnemyController ec;
			if (ec = target.GetComponent<EnemyController>()) {
				if (ec.dead) {
					hasTarget = patrolPoints.Length != 0;
					if (hasTarget) {
						target = patrolPoints[0];
					} else {
						target = null;
						rb.bodyType = RigidbodyType2D.Static;
					}

					playerNoticed = false;

					TargetDead();
					return;
				}
			}

			move = target.position - transform.position;
			float dist = move.magnitude;
			Quaternion rot = Quaternion.LookRotation(move, Vector3.back);
			rot.x = 0;
			rot.y = 0;
			transform.rotation = rot;
			if (dist < closeDist) {
				if (target.CompareTag("Player")) {
					CloseToTarget();
				} else {
					move /= dist;
					if (dist < minDist) {
						if (targetCount >= patrolPoints.Length - 1 || targetCount <= 0) {
							patrolDir = -patrolDir;
						}
						targetCount += patrolDir;

						target = patrolPoints[targetCount];
					}
				}
			} else {
				move /= dist;
				AwayFromTarget();

				anim.SetBool("Run", true);
			}
		} else {
			move = Vector3.zero;
			anim.SetBool("Run", false);
		}

		if (playerNoticed) {
			hasTarget = true;

			NoticePlayer();
		} else {
			Vector3 toPlayer = player.transform.position - transform.position;
			RaycastHit2D hit = Physics2D.Raycast(transform.position, toPlayer, toPlayer.magnitude, LayerMask.GetMask("Level"));
			if (!hit) {
				playerNoticed = true;
				isAwake = true;
				target = player.transform;

				if (!isAwake) GameObject.Find("-GAME LOOP-").SendMessage("EnemySeen");
			} else {
				Transform enemy;
				if (enemy = player.transform.GetComponent<PlayerController>().enemy) {
					toPlayer = enemy.position - transform.position;
					hit = Physics2D.Raycast(transform.position, toPlayer, toPlayer.magnitude, LayerMask.GetMask("Level"));

					if (!hit) {
						playerNoticed = true;
						isAwake = true;
						target = enemy.transform;

						if (!isAwake) GameObject.Find("-GAME LOOP-").SendMessage("EnemySeen");
					}
				}
			}
		}
	}

	protected abstract void Init();

	protected abstract void UpdateEnemy();

	protected abstract void NoticePlayer();

	protected abstract void HitTarget();

	protected abstract void AwayFromTarget();

	protected abstract void CloseToTarget();

	protected abstract void Attack();

	protected abstract void StopAttack();

	protected abstract void TakenOver();

	protected abstract void PlayerAvoidedAttack();

	protected abstract void TargetDead();

	IEnumerator StopBlood(float time) {
		yield return new WaitForSeconds(time);

		blood.Pause();
	}

	IEnumerator StopInsideBlood(float time) {
		yield return new WaitForSeconds(time);

		insideBlood.Pause();
	}

	public virtual void Kill(Vector2 dir, DeathStyle style) {
		if (dead) return;

		killDir = dir;

		transform.rotation = Quaternion.Euler(0, 0, Mathf.Atan2(dir.y, dir.x) * Mathf.Rad2Deg + 90);

		Kill(style);
	}

	protected void Kill(DeathStyle style) {
		this.style = style;

		if (isAwake)
			GameLoop.EnemyDead();
		anim.enabled = false;

		foreach (SpriteRenderer renderer in GetComponentsInChildren<SpriteRenderer>()) {
			renderer.enabled = false;
		}

		sr.enabled = true;

		switch (style) {
			case DeathStyle.DECAP:
				sr.sprite = decapSprite;
				break;

			case DeathStyle.SHOT:
				sr.sprite = shotSprite;
				break;

			case DeathStyle.EXPLOSION:
				sr.enabled = false;
				break;
		}

		sr.transform.Rotate(0, 0, 180);

		blood.Play();
		dead = true;
		StartCoroutine(StopBlood(3f));
		rb.simulated = false;
		foreach (Collider2D col in GetComponentsInChildren<Collider2D>()) {
			col.enabled = false;
		}

		detail.ColorFromPos(Color.HSVToRGB(UnityEngine.Random.Range(0.0f, 1.0f), 1.0f, 1.0f), 40, transform.position);

		if (!beingControlled) return;

		beingControlled = false;
		player.GetComponent<PlayerController>().LoseControl();
	}

	public void KillInside(DeathStyle style) {
		if (dead) return;

		inside = true;

		insideBlood.Play();
		StartCoroutine(StopInsideBlood(3f));
		Kill(style);
		blood.Stop();
	}

	internal void TakeOver() {
		beingControlled = true;
		firstFrame = true;

		rb.bodyType = RigidbodyType2D.Dynamic;

		gameObject.tag = "Player";
		gameObject.layer = LayerMask.NameToLayer("Player");
	}

	public void ReplayReset() {
		blood.Simulate(0, true, true);
		insideBlood.Simulate(0, true, true);
		dead = false;
		sr.sprite = defaultSprite;

		anim.enabled = true;
		anim.Play("Idle");

		foreach (SpriteRenderer renderer in GetComponentsInChildren<SpriteRenderer>()) {
			renderer.enabled = true;
		}
	}

	public void ReplayData(int frame, object[] data) {
		transform.position = (Vector3)data[0];
		transform.rotation = (Quaternion)data[1];
		transform.localScale = (Vector3)data[2];

		if ((bool)data[3]) {
			DeathStyle style = (DeathStyle)data[4];

			if ((bool)data[5]) KillInside(style);
			else Kill((Vector3)data[6], style);
		}

		SetAnimationData((object[])data[7]);
	}

	public object[] CollectData() {
		bool killed = dead && !lastDead;

		lastDead = dead;

		return new object[] { transform.position, transform.rotation, transform.localScale, killed, style, inside, killDir, GetAnimationData() };
	}

	protected abstract object[] GetAnimationData();
	protected abstract void SetAnimationData(object[] data);

	public void ReplayEnded() {	}
}
