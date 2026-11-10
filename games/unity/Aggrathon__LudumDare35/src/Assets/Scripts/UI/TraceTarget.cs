using UnityEngine;
using System.Collections;

public class TraceTarget : MonoBehaviour {

	Unit unit;
	public LineRenderer moveLine;
	public LineRenderer attackLine;

	void Start () {
		unit = GetComponentInParent<Unit>();
	}
	
	void Update () {
		moveLine.SetPosition(0, transform.position);
		moveLine.SetPosition(1, unit.destination + Vector3.up * 0.5f);
		attackLine.enabled = true;
		attackLine.SetPosition(0, transform.position);
		attackLine.SetPosition(1, unit.target != null ? unit.target.transform.position + Vector3.up * 0.5f : transform.position);
	}
}
