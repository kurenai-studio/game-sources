using UnityEngine;
using System.Collections;

public class PlayerController : MonoBehaviour {

	public Texture textureBubbleNazi;
	
	private Rigidbody rb;
	private Vector2 screenPos;
	
	private const float SPEED = 6.0f;
	private const float JUMP_SPEED = 8.0f;
	private const float GRAVITY = 20.0f;
	
	//private Vector3 moveDirection = Vector3.zero;
	private bool isTalking = false;
	private bool isInTribune = false;
	
	// Use this for initialization
	void Start ()
	{
		rb = GetComponent<Rigidbody> ();
	}
	
	// Update is called once per frame
	void Update ()
	{
		float moveHorizontal = Input.GetAxis ("Horizontal") * Time.deltaTime * 50.0f;
		float moveVertical = Input.GetAxis ("Vertical") * Time.deltaTime * 50.0f;
		
		//Vector3 movement = new Vector3 (Mathf.Cos (transform.localEulerAngles.y*Mathf.PI/180.0f), 0.0f, Mathf.Sin (transform.localEulerAngles.y*Mathf.PI/180.0f));
		//transform.localEulerAngles = new Vector3 (transform.localEulerAngles.x, transform.localEulerAngles.y + moveHorizontal, transform.localEulerAngles.z);
		Vector3 movement = new Vector3 (moveHorizontal, 0f, moveVertical);

		rb.AddForce (movement * 500.0f);
		rb.velocity = rb.velocity * Time.deltaTime * 0.2f;
		
		//----------------------
		// movement
		
		/*CharacterController controller = GetComponent<CharacterController>();
		if (controller.isGrounded || true) {
			moveDirection = new Vector3(Input.GetAxis("Horizontal")*1.0f, 0, Input.GetAxis("Vertical")*1.0f);
			moveDirection = transform.TransformDirection(moveDirection);
			moveDirection *= SPEED;
			if (Input.GetButton("Jump"))
				moveDirection.y = JUMP_SPEED;
			moveDirection.y -= GRAVITY * Time.deltaTime;
			controller.Move(moveDirection * Time.deltaTime);
		}*/
		
		//----------------------
		// talking
		
		isTalking = false;
		foreach (GameObject go in GameObject.FindGameObjectsWithTag("personage")) {
			if (isNear (go.transform.position)) {
				isTalking = true;
				PersonageController script = (PersonageController)go.GetComponent (typeof(PersonageController));
				if (script != null && !script.isVictim ())
					script.listenToBullshit ();
			}
		}
	}

	void FixedUpdate() {
		Vector3 screenPos3D = Camera.main.WorldToScreenPoint(transform.position);
		screenPos = new Vector2 (screenPos3D.x, screenPos3D.y);
	}
	
	public bool isNear(Vector3 v) {
		return Vector3.Distance (transform.position, v) < 3;
	}
	
	public Vector3 getPosition() {
		return transform.position;
	}
	
	public void setInTribune(bool yesNo) {
		isInTribune = yesNo;
	}
	
	void OnGUI()
	{
		if (isTalking == true && !isInTribune) {
			//65,120
			GUI.DrawTexture (new Rect (screenPos.x - 35, (Screen.height - screenPos.y) - 80, 50, 50), textureBubbleNazi);
		}
	}
}
