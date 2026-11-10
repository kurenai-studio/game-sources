using UnityEngine;

public class ClickMove : MonoBehaviour {
	
	void Update () {
		if(Input.GetMouseButtonDown(0))
		{
			RaycastHit hit;
			if(Physics.Raycast(Camera.main.ScreenPointToRay(Input.mousePosition), out hit)) {
				GetComponent<UnityEngine.AI.NavMeshAgent>().destination = hit.point;
			}
		}
	}
}
