using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Manipulator : MonoBehaviour {

	public IEnumerator MoveTo(Vector3 pos2, float duration){
		Vector3 pos1 = transform.position;
		float dt = 0f;
		do{
			transform.position = new Vector3(
				Mathf.Lerp(pos1.x, pos2.x, dt/duration),
				Mathf.Lerp(pos1.y, pos2.y, dt/duration),
				0f
			);
			dt += Time.deltaTime;
			yield return new WaitForEndOfFrame();
		}while(dt<duration);
	}
}

