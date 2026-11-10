using UnityEngine;
using System.Collections;

public class SpawnTeamAndShapeshift : MonoBehaviour {
	public int shape = 1;

	void Update ()
	{
		GameObject.FindObjectOfType<TeamController>().SpawnTeam();
		GameData.instance.playerTeam.autoSelect = false;
		GameObject.FindObjectOfType<TeamController>().Shapeshift(shape);
		enabled = false;
	}
}
