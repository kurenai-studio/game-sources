using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PatrolVisualizer : MonoBehaviour {

#if UNITY_EDITOR
	public bool showPath;
	void OnDrawGizmos()
	{
		if(showPath) {
			int count = transform.childCount;
			float step = 0.9f / (float)count;
			for (int i = 0; i < count; i++)
			{
				Transform t1 = transform.GetChild(i);
				Transform t2 = transform.GetChild((i + 1) % count);
				Vector3 offset = t1.right * 0.05f;
				Gizmos.color = Color.red;
				Gizmos.DrawSphere(t1.position, 1f);
				Gizmos.color = Color.red * (1f-i*step) + Color.white*(i*step);
				Gizmos.DrawLine(t1.position, t2.position);
				Gizmos.DrawLine(t1.position + offset, t2.position + offset);
				Gizmos.DrawLine(t1.position - offset, t2.position - offset);
			}
		}
	}
#endif
}
