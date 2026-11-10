using UnityEngine;
using System.Collections;

public class SpawnEnemies : MonoBehaviour {
	
	
	void Update () {
		EnemyController en = GameObject.FindObjectOfType<EnemyController>();
		
		Transform go = (Transform)GameObject.Instantiate(GameData.instance.enemyTeam.spawnPoint);
		go.Translate(Vector3.right * 10);
		en.target = go;

		GameData.instance.enemyTeam.spawnSize += 5;
		en.SpawnTeam();

		Unit[] us = new Unit[GameData.instance.enemyTeam.selectedUnits.Count];
		for (int i = 0; i < GameData.instance.enemyTeam.selectedUnits.Count; i++)
		{
			us[i] = GameData.instance.enemyTeam.selectedUnits[i];
		}
		for (int i = 0; i < us.Length; i++)
		{
			us[i].Shapeshift(GameData.instance.unitTypes.units[1]);
		}
		enabled = false;
	}
}
