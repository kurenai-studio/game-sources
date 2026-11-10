using UnityEngine;
using System.Collections.Generic;

public class PlayerController : MonoBehaviour, IReplayable {
	private Rigidbody2D rb;
	public int speed = 5;
	public Vector2 inputVelocity;

	private Transform scytheLocation;
	private Transform scythe;
	public static readonly float scytheCooldown = 0.5f;
	private float scytheCooldownTimer = scytheCooldown;
	private Quaternion lockedRot;
	private BoxCollider2D scytheCollider;
	private ContactFilter2D enemyContactFilter;
	private ContactFilter2D enemyBossContactFilter;

	private CircleCollider2D mouseCollider;
	private Transform mouseColliderTransform;
	public float teleportCooldown = 4f;
	private float teleportTimer;
	private ParticleSystem ps;

	private Animator anim;
	private bool attackTrigger;

	private float timeScaleTarget = 1;
	private List<GameObject> killers = new List<GameObject>();

	private float enemyControlCooldown = 5f;
	private float enemyControlTimer;
	private bool controllingEnemy;
	public Transform enemy;
	private Transform orb;
	public float orbSpeed;
	public SpriteRenderer orbRender;

	private Collider2D winCol;
	private Collider2D playerCol;

	public GameObject scythePrefab;
	private GameObject attackingScythe;
	public bool scytheThrown;
	private SpriteRenderer sr;
	public bool knockedBack;

	void Start() {
		rb = GetComponent<Rigidbody2D>();
		scytheLocation = transform.Find("Sprite").Find("Player Arm").Find("Scythe location");
		scythe = transform.Find("Sprite").Find("Scythe");
		scytheCollider = scythe.GetComponent<BoxCollider2D>();
		sr = scythe.GetComponent<SpriteRenderer>();
		ps = transform.Find("Teleport particles").GetComponent<ParticleSystem>();

		mouseColliderTransform = transform.Find("Mouse collider");
		mouseCollider = mouseColliderTransform.GetComponent<CircleCollider2D>();

		anim = GetComponent<Animator>();

		enemyContactFilter = new ContactFilter2D {
			useLayerMask = true,
			layerMask = LayerMask.GetMask("Enemy")
		};

		enemyBossContactFilter = new ContactFilter2D {
			useLayerMask = true,
			layerMask = LayerMask.GetMask("Enemy") | LayerMask.GetMask("Boss")
		};

		winCol = GameObject.Find("Win").GetComponent<Collider2D>();
		playerCol = GetComponent<Collider2D>();

		orb = transform.Find("Orb");
		orbRender = orb.GetComponentInChildren<SpriteRenderer>();
	}

	void Update() {
		if (Replay.IN_REPLAY || knockedBack) return;

		Time.timeScale += (timeScaleTarget - Time.timeScale) / 10f;

		if (Time.timeScale < 0.05) Time.timeScale = 0;
		if (Time.timeScale > 0.95) Time.timeScale = 1;

		if (controllingEnemy) return;

		inputVelocity = new Vector2(Input.GetAxis("Horizontal"), Input.GetAxis("Vertical"));

		//Check if player has met victory conditions
		if (winCol.IsTouching(playerCol)) {
			GameLoop.NextLevel();
		}

		//Look at mouse
		Vector3 mouseWorldPos = Camera.main.ScreenToWorldPoint(Input.mousePosition);
		mouseColliderTransform.position = mouseWorldPos;

		if (Time.timeScale < 0.1) goto timestop;

		//Look at mouse
		if (scytheCooldownTimer < scytheCooldown * 0.7f) {
			lockedRot = transform.rotation;
		} else if (scytheCooldownTimer < scytheCooldown) { //When cooldown is 70% done
			Vector3 toMouse = mouseWorldPos - transform.position;

			Quaternion rot = Quaternion.LookRotation(toMouse, Vector3.back);
			rot.x = 0;
			rot.y = 0;

			rot.eulerAngles = Mathf.LerpAngle(lockedRot.eulerAngles.z, rot.eulerAngles.z, (scytheCooldownTimer / scytheCooldown - 0.7f) / (1 - 0.7f)) * Vector3.forward;
			transform.rotation = rot;
		} else { //When cooldown is done
			Vector3 toMouse = mouseWorldPos - transform.position;

			Quaternion rot = Quaternion.LookRotation(toMouse, Vector3.back);
			rot.x = 0;
			rot.y = 0;
			transform.rotation = rot;
		}

		//Swing scythe
		scytheCooldownTimer += Time.deltaTime;
		if (!scytheThrown) {
			if (scytheCooldownTimer > scytheCooldown) {
				if (Input.GetButtonDown("Attack")) {
					anim.SetTrigger("Attack");

					attackTrigger = true;

					scytheCooldownTimer = 0;
				}
			} else { //Is swinging
				Collider2D[] cols = new Collider2D[1];
				if (scytheCollider.OverlapCollider(enemyBossContactFilter, cols) != 0) {
					if (cols[0].gameObject.CompareTag("Enemy")) {
						cols[0].gameObject.GetComponent<EnemyController>().Kill(cols[0].transform.position - transform.position, EnemyController.DeathStyle.DECAP);
					}
				}
			}
		}

		//Taking over enemies
		enemyControlTimer -= Time.deltaTime;
		if (enemyControlTimer < 0) {
			if (!orb.gameObject.activeSelf) orb.gameObject.SetActive(true);

			orb.Rotate(0, 0, orbSpeed * Time.deltaTime);

			if (Input.GetButtonDown("Enemy Control")) {
				Collider2D[] cols = new Collider2D[4];
				int colNum;
				if ((colNum = mouseCollider.OverlapCollider(enemyContactFilter, cols)) != 0) {
					float dist = float.PositiveInfinity;
					int index = -1;
					for (int i = 0; i < colNum; i++) {
						float currDist = (cols[i].transform.position - transform.position).sqrMagnitude;
						if (currDist < dist) {
							dist = currDist;
							index = i;
						}
					}

					enemyControlTimer = enemyControlCooldown;

					if (orb.gameObject.activeSelf) orb.gameObject.SetActive(false);

					controllingEnemy = true;
					enemy = cols[index].transform;
					Camera.main.GetComponent<CameraController>().SetTarget(cols[index].transform);
					cols[index].GetComponent<EnemyController>().TakeOver();
				}
			}
		}

		timestop:

		//Teleport
		mouseColliderTransform.position = mouseWorldPos;

		teleportTimer -= Time.deltaTime;
		if (teleportTimer < 0) {
			if (!ps.isPlaying) ps.Play();
			if (Input.GetButtonDown("Teleport")) {
				Collider2D[] cols = new Collider2D[4];
				int colNum;
				if ((colNum = mouseCollider.OverlapCollider(enemyContactFilter, cols)) != 0) {
					float dist = float.PositiveInfinity;
					int index = -1;
					for (int i = 0; i < colNum; i++) {
						float currDist = (cols[i].transform.position - transform.position).sqrMagnitude;
						if (currDist < dist) {
							dist = currDist;
							index = i;
						}
					}

					teleportTimer = teleportCooldown;

					transform.position = cols[index].transform.position;
					cols[index].GetComponent<EnemyController>().KillInside(EnemyController.DeathStyle.EXPLOSION);

					if (timeScaleTarget != 1) {
						timeScaleTarget = 1;

						foreach (GameObject killer in killers) {
							killer.SendMessage("PlayerAvoidedAttack");
						}

						killers.Clear();
					}
				}
			}
		} else {
			if (!ps.isStopped) ps.Stop();
		}

		//Throw scythe
		if (Input.GetButtonDown("Throw") && !scytheThrown && scytheCooldownTimer > scytheCooldown) {
			attackingScythe = Instantiate(scythePrefab, scytheLocation.position, scythe.rotation);
			attackingScythe.GetComponent<Scythe>().dir = transform.up;

			sr.enabled = false;

			scytheThrown = true;
		}
	}

	void FixedUpdate() {
		if (knockedBack) return;
		if (Replay.IN_REPLAY) return;

		//Player movement
		if (!controllingEnemy) rb.velocity = inputVelocity * speed * Time.fixedDeltaTime;
		else rb.velocity = Vector3.zero;

		//Handle scythe location
		scythe.position = scytheLocation.position;
	}

	public void LoseControl() {
		controllingEnemy = false;
		enemy = null;
		Camera.main.GetComponent<CameraController>().SetTarget(transform);
	}

	public void Kill(GameObject killer) {
		if (Replay.IN_REPLAY) {
			return;
		}

		if (teleportTimer < 0 && !killer.GetComponent<Boss>()) {
			//Final chance

			killers.Add(killer);

			if (timeScaleTarget == 0) return;

			timeScaleTarget = 0;
			Time.timeScale = 0.1f;
		} else {
			Replay.ReplayBackwards();
		}
	}

	void OnCollisionEnter2D(Collision2D collision) {
		if (knockedBack) knockedBack = false;
	}

	public void ScytheReturned() {
		scytheThrown = false;

		sr.enabled = true;
	}

	public void ReplayData(int frame, object[] data) {
		transform.position = (Vector3)data[0];
		transform.rotation = (Quaternion)data[1];
		transform.localScale = (Vector3)data[2];
		sr.enabled = (bool)data[3];

		if ((bool)data[7]) anim.SetTrigger("Attack");

		if (!(bool)data[4]) {
			if (scytheThrown) Destroy(attackingScythe);

			scytheThrown = false;
			return;
		}

		if (!scytheThrown) {
			attackingScythe = Instantiate(scythePrefab, scytheLocation.position, scythe.rotation);

			scytheThrown = true;
		}

		attackingScythe.transform.position = (Vector3)data[5];
		attackingScythe.transform.rotation = (Quaternion)data[6];
	}

	public object[] CollectData() {
		bool atkTrig = attackTrigger;
		attackTrigger = false;
		return new object[] {	transform.position, 
								transform.rotation, 
								transform.localScale, 
								sr.enabled, 
								scytheThrown,
								scytheThrown ? attackingScythe.transform.position : Vector3.zero, 
								scytheThrown ? attackingScythe.transform.rotation : Quaternion.identity,
								atkTrig };
	}

	public void ReplayEnded() {
		if (attackingScythe) Destroy(attackingScythe);

		ScytheReturned();
	}

	public void ReplayReset() {
		orb.gameObject.SetActive(false);
		ps.Stop();
	}
}
