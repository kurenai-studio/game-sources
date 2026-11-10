using UnityEngine;
using UnityEngine.Events;

public class PlayerInteraction : MonoBehaviour {

	public Transform tracker;
	public UnityEvent onInteract;
	public bool oneShot = true;
	Transform player;

	void Start () {
		player = GameState.instance.player.transform;
	}
	

	void Update () {
		Vector3 dir = player.position - tracker.position;
		dir.y = 0;
		tracker.rotation = Quaternion.LookRotation(dir, Vector3.up);
		if(Input.GetButtonUp("Interact"))
		{
			onInteract.Invoke();
			if (oneShot)
				gameObject.SetActive(false);
		}
	}
}
