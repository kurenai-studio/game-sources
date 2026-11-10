using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[DisallowMultipleComponent]
[RequireComponent(typeof(CharacterController))]
public class FPSController : MonoBehaviour {

	public float speed = 5f;

	[Header("Sprint")]
	public float sprintLength = 2f;
	public float sprintRecovery = 5f;
	public float sprintSpeed = 8f;
	public float sprintAmount = 0f;

	[Header("Abilities")]
	public int numThrowable = 0;
	public bool hasBucket = false;
	public float throwSpeed = 5f;
	public GameObject throwablePrefab;
	public float bucketDistance = 3f;

	CharacterController cc;
	
	void Start () {
		cc = GetComponent<CharacterController>();
	}
	
	void Update ()
	{
		float moveSpeed = speed;
		if (Input.GetButton("Sprint") && sprintAmount > 0f)
		{
			moveSpeed = sprintSpeed;
			sprintAmount -= Time.deltaTime / sprintLength;
		}
		else
		{
			sprintAmount += Time.deltaTime / sprintRecovery;
			if (sprintAmount > 1f) sprintAmount = 1f;
		}
		transform.rotation *= Quaternion.Euler(0, Input.GetAxis("Mouse X"), 0);
		cc.SimpleMove(transform.rotation*new Vector3(Input.GetAxis("Horizontal"), 0f, Input.GetAxis("Vertical")).normalized*moveSpeed);
		//cc.Move(transform.rotation * new Vector3(Input.GetAxis("Horizontal"), 0f, Input.GetAxis("Vertical")).normalized * (moveSpeed * Time.deltaTime));
		Camera.main.transform.rotation *= Quaternion.Euler(-Input.GetAxis("Mouse Y"), 0, 0);

		if(Input.GetButtonUp("Gadget"))
		{
			RaycastHit hit;
			if (hasBucket && Physics.Raycast(transform.position + transform.forward * 0.5f, Camera.main.transform.forward, out hit, bucketDistance))
			{
				RobotAI ai = hit.transform.GetComponent<RobotAI>();
				if(ai != null)
				{
					hasBucket = false;
					ai.Disable();
				}
			}
			else if (numThrowable > 0)
			{
				numThrowable--;
				GameObject go = Instantiate(throwablePrefab, Camera.main.transform.position + Camera.main.transform.forward, new Quaternion(0, 0, 0, 1));
				go.GetComponent<Rigidbody>().velocity = Camera.main.transform.forward * throwSpeed;
			}
		}
	}

	public void AddThrowable()
	{
		numThrowable++;
	}

	public void PickupBucket()
	{
		hasBucket = true;
	}
}
