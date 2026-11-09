using UnityEngine;
using System.Collections;

public class PersonageController : MonoBehaviour {
	
	//--------
	// public objects

	public Texture textureBubbleLogo;
	
	//--------
	// constants

	private const bool EASY_DEBUG_MODE = false;
	private const float HEIGHT_RAISED_HAND = 0.3f;
	
	private const float SPEED_NAZIFICATION = EASY_DEBUG_MODE ? 10f : 0.5f;
	private const float SPEED_UNNAZIFICATION = 0.05f;
	private const float SPEED_VICTIMATION = EASY_DEBUG_MODE ? 0.1f : 0.02f;
	private const float SPEED_VICTIMATION_PRISON = EASY_DEBUG_MODE ? 0.1f : 0.02f;
	
	private const float SPEED_BLUE_BECOME_YELLOW = 0.5f;

	enum BehaviourMode { BEHAVIOUR_WANDERING, BEHAVIOUR_TARGET_POS_TRIBUNE, BEHAVIOUR_TARGET_POS_PRISON, BEHAVIOUR_TARGET_VICTIM };

	private const float DURATION_CHANGE_WANDERING_DIRATION = 1.0f;

	//--------
	// private stuff

	private Camera mainCamera;
	private Renderer thisRenderer;
	private Rigidbody rb;
	private GameController gameControllerScript = null;

	private float nazification = 0f;
	private float victimation = 0f;
	private float life = 15f;

	//private Vector3 screenPos;
	private float nextRandomTime = -1;

	private Vector3 mvtVector = new Vector3(0.0f, 0.0f, 0.0f);

	BehaviourMode behaviour;
	private Vector3 m_targetPos;
	private GameObject m_targetVictim = null;

	private bool isIrrecoverableNazi = false;
	private bool m_isInPrison = false;
	private bool m_isTargetPrison = false;

	//--------
	// code

	// Use this for initialization
	void Start () {
		mainCamera = Camera.main;
		rb = GetComponent<Rigidbody> ();
		gameControllerScript = (GameController) GameObject.FindGameObjectsWithTag("GameController")[0].GetComponent(typeof(GameController));
		thisRenderer = GetComponent<Renderer>();

		transform.localEulerAngles = new Vector3 (0f, (float)Random.Range(-180, 180), 0f);
		setColor (Color.blue);

		nextRandomTime = Time.time + Random.value*DURATION_CHANGE_WANDERING_DIRATION;
	}

	void setColor(Color c) {
		foreach (Renderer childRenderer in GetComponentsInChildren<Renderer>()) {
			childRenderer.material.color = c;
		}
	}

	// Update is called once per frame
	void Update () {

		//screenPos = mainCamera.WorldToScreenPoint(transform.position);
		
		raiseHand(behaviour == BehaviourMode.BEHAVIOUR_TARGET_POS_TRIBUNE && !m_isTargetPrison);

		if (isDead()) {
			setColor (Color.grey);
		} else {
			if (behaviour == BehaviourMode.BEHAVIOUR_TARGET_POS_TRIBUNE || 
			    behaviour == BehaviourMode.BEHAVIOUR_TARGET_POS_PRISON || 
			    behaviour == BehaviourMode.BEHAVIOUR_TARGET_VICTIM) {

				Vector3 target = m_targetPos;
				if (behaviour == BehaviourMode.BEHAVIOUR_TARGET_VICTIM) target = m_targetVictim.transform.position;

				float distToTarget = Vector3.Distance (target, transform.position);
				float coeffSpeed = distToTarget < 1f ? 3f * distToTarget : 3f;
				Vector3 vMvt = (target - transform.position) * Time.deltaTime / Vector3.Distance (target, transform.position);
				if (!isVictim ())
					transform.localEulerAngles = new Vector3 (0f, Mathf.Atan2 (vMvt.z, vMvt.x) * 180f / Mathf.PI, 0f);
				transform.position += vMvt * coeffSpeed;
			} else if (!m_isInPrison) {

				if (Time.time > nextRandomTime) {

					nextRandomTime = Time.time + DURATION_CHANGE_WANDERING_DIRATION;
					mvtVector = new Vector3 (
					((float)Random.Range (0, 2000)) / 1000.0f - 1.0f, 
					0.0f, 
					((float)Random.Range (0, 2000)) / 1000.0f - 1.0f);
					if (!isVictim ())
						transform.localEulerAngles = new Vector3 (0f, Mathf.Atan2 (mvtVector.z, mvtVector.x) * 180f / Mathf.PI, 0f);
				}
				transform.position += new Vector3 (mvtVector.x * Time.deltaTime * 1.0f, 0.0f, mvtVector.z * Time.deltaTime * 1.0f);
			}

			if (gameControllerScript.isModeBlueEqualYellow () && !isNazi () && !isVeryVictim ()) {
				victimation = victimation + Time.deltaTime * SPEED_BLUE_BECOME_YELLOW;
			}
		
			/*transform.position = new Vector3(transform.position.x, 1f-0.5f*Mathf.Sin (Time.time/1f), transform.position.z);
			transform.localEulerAngles -= new Vector3 (
				transform.localEulerAngles.x * Time.deltaTime * 1.0f,
				transform.localEulerAngles.y * Time.deltaTime * 1.0f,
				transform.localEulerAngles.z * Time.deltaTime * 1.0f);*/
		
			//--------
			// set color

			float nazificationColor = Mathf.Min (nazification, 1f);
			setColor (new Color (Mathf.Max (nazificationColor, victimation), victimation, 1f - Mathf.Max (nazificationColor, victimation), 1f));
		
			//--------
			// unnazify if recoverable

			if (isIrrecoverableNazi) {
				if (nazification < 1.2f)
					nazification += Time.deltaTime * SPEED_NAZIFICATION;
			} else {
				nazification -= Time.deltaTime * SPEED_UNNAZIFICATION;
				if (nazification < 0f) nazification = 0f;
			}

			//--------
			// in prison => lose life

			if (m_isInPrison) life -= SPEED_VICTIMATION_PRISON;
		}

		//--------
		// destroy if dead

		/*if (isDead()) {
			foreach (GameObject go in GameObject.FindGameObjectsWithTag("personage")) {
				PersonageController script2 = (PersonageController) go.GetComponent(typeof(PersonageController));
				if (script2 != null && !script2.m_targetVictim == gameObject)
					script2.setWandering();
			}
			//Destroy (gameObject);
		}*/
	}

	void OnCollisionEnter(Collision col) {
		if (col.gameObject.tag == "player" || col.gameObject.tag == "personage") {
			float magnitude = col.gameObject.GetComponent<Rigidbody> ().velocity.magnitude;
			if (isVictim()) {
				life -= magnitude * SPEED_VICTIMATION;
			}
			if (col.gameObject.tag == "player" && !m_isTargetPrison) {
				victimation += magnitude * SPEED_VICTIMATION;
				nazification = 0f;
				//setWandering();
			}
		}
	}
	
	public Vector3 getTargetPosition() { return m_targetPos; }
	
	//----------
	// wandering mode
	
	public void setWandering() { behaviour = BehaviourMode.BEHAVIOUR_WANDERING; }

	//----------
	// target tribune mode

	public void setTargetTribune(Vector3 newTargetPos) { 
		m_targetPos = newTargetPos;
		behaviour = BehaviourMode.BEHAVIOUR_TARGET_POS_TRIBUNE;
	}

	public float getDistanceTo(Vector3 v) { return Vector3.Distance(transform.position, v); }

	//----------
	// target victim mode

	public bool isTargetVictimSet() { return behaviour == BehaviourMode.BEHAVIOUR_TARGET_VICTIM; }
	public void setTargetVictim(GameObject newTargetVictim) { 
		m_targetVictim = newTargetVictim;
		behaviour = BehaviourMode.BEHAVIOUR_TARGET_VICTIM; 
	}
	public GameObject getTargetVictim() { return m_targetVictim; }

	//----------
	// target prison mode

	public void setTargetPrison() { 
		Vector3 prisonPos = GameObject.FindGameObjectWithTag ("prison").transform.position + new Vector3 (3f, 0f, 0f);
		m_targetPos = prisonPos;
		behaviour = BehaviourMode.BEHAVIOUR_TARGET_POS_PRISON;
	}
	
	public float getDistanceToPrison() { 
		Vector3 prisonPos = GameObject.FindGameObjectWithTag ("prison").transform.position + new Vector3 (3f, 0f, 0f);
		return Vector3.Distance (prisonPos, transform.position);
	}
	
	public bool isTargetPrison() { return behaviour == BehaviourMode.BEHAVIOUR_TARGET_POS_PRISON;	}
	public bool isInPrison() { return m_isInPrison; }
	public void setInPrison() { m_isInPrison = true; }
	
	//----------
	// raise/unraise hand

	private void raiseHand(bool yesNo) {
		foreach (Transform childTransform in GetComponentsInChildren<Transform>())
		{
			if (childTransform != transform) {

				if (yesNo) {
					if (childTransform.localEulerAngles.z > -90.0f) {
						childTransform.localEulerAngles -= new Vector3(0f, 0f, Time.deltaTime * 1f);
						if (childTransform.localEulerAngles.z < -90.0f) 
							childTransform.localEulerAngles = new Vector3(childTransform.localEulerAngles.x, childTransform.localEulerAngles.y, -90.0f);
					}
					if (childTransform.position.y < transform.position.y + HEIGHT_RAISED_HAND) {
						childTransform.position += new Vector3(0f, Time.deltaTime * 1f, 0f);
						if (childTransform.position.y > transform.position.y + HEIGHT_RAISED_HAND)
							childTransform.position = new Vector3(childTransform.position.x, transform.position.y + HEIGHT_RAISED_HAND, childTransform.position.z);
					}
				} else {
					if (childTransform.localEulerAngles.z < 0.0f) {
						childTransform.localEulerAngles += new Vector3(0f, 0f, Time.deltaTime * 1f);
						if (childTransform.localEulerAngles.z > 0.0f) 
							childTransform.localEulerAngles = new Vector3(childTransform.localEulerAngles.x, childTransform.localEulerAngles.y, 0.0f);
					}
					if (childTransform.position.y > transform.position.y) {
						childTransform.position -= new Vector3(0f, Time.deltaTime * 1f, 0f);
						if (childTransform.position.y < transform.position.y)
							childTransform.position = new Vector3(childTransform.position.x, transform.position.y, childTransform.position.z);
					}
				}
			}
		}
	}
	
	public bool isNazi() { return nazification >= 0.5f; }
	public bool isVeryNazi() { return nazification >= 1f; }
	public bool isVictim() { return victimation > 0.7f; }
	public bool isVeryVictim() { return victimation >= 1f; }
	public bool isDead() { return life < 0f; }
	
	public void listenToBullshit() { nazification += Time.deltaTime * SPEED_NAZIFICATION; }

	public void setIrrecoverableNazi() {
		isIrrecoverableNazi = true;
		victimation = 0.0f;
	}
	
	void OnGUI() {
		/*if (isNazi() && m_useTargetPos) {
			GUI.DrawTexture (new Rect (screenPos.x - 70, (Screen.height - screenPos.y) - 150, 50, 50), textureBubbleLogo);
		}

		if (isVictim())
		GUI.Label (new Rect (screenPos.x - 70, (Screen.height - screenPos.y) - 150, Screen.width, Screen.height), 
			           " " + life + " " + (int)behaviour);
	//	           "[" + transform.eulerAngles.x + " , " + transform.eulerAngles.y + " , " + transform.eulerAngles.z + " " + rb.IsSleeping() + "]");
		*/
	}

}
