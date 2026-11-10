using UnityEngine;
using System.Collections;

public class EnemyController : MonoBehaviour {

	GameData data;
	public EnemyStance.Stance aiStance = EnemyStance.Stance.moreTanks;
	public int minWaveSize = 5;
	public float startDelay = 10f;
	public float unitSpace = 3;
	public Transform target;
	public float targetSpread = 10f;
	public float cheat = 1f;

	void Start () {
		data = GameData.instance;
		if(target == null)
		{
			target = GameObject.FindGameObjectWithTag("Finish").transform;
		}
		StartCoroutine(FirstSpawn());
	}

	IEnumerator FirstSpawn()
	{
		yield return new WaitForSeconds(startDelay);
		SpawnTeam();
	}

	public void SpawnTeam()
	{
		int spawnSize = data.enemyTeam.spawnSize;
		if (spawnSize < minWaveSize)
			return;

		//CHEAT
		spawnSize = (int)(((float)spawnSize)*cheat);

		Transform orig = data.enemyTeam.spawnPoint;
		float rad = spawnSize > 1 ? spawnSize * unitSpace * 0.5f / Mathf.PI : 0f;
		GameObject prefab = data.unitTypes.units[0];

		for (int i = 0; i < spawnSize; i++)
		{
			GameObject go = GameObjectPool.Get(prefab);
			go.transform.position = orig.position + Quaternion.AngleAxis(360f / spawnSize * i, orig.up) * Vector3.forward * rad;
			go.transform.rotation = orig.rotation;
			Unit u = go.GetComponent<Unit>();
			u.Spawn(data.enemyTeam, prefab);
			data.enemyTeam.selectedUnits.Add(u);

			u.enemySighted += (unit, target, first) => {
				if(unit.type.name == "Truck")
					unit.Shapeshift(data.unitTypes.units[EnemyStance.GetResponse(target.type.name, aiStance)]);
				if(first && data.enemyTeam.selectedUnits.Count > 0)
				{
					Unit un = data.enemyTeam.selectedUnits[data.enemyTeam.selectedUnits.Count - 1];
					if (un != unit)
						un.Shapeshift(data.unitTypes.units[EnemyStance.GetResponse(target.type.name, aiStance)]);
				}
			};
			u.unitDied += (un, t, f) => { SpawnTeam(); };
			
			Vector2 rnd = Random.insideUnitCircle * targetSpread;
			u.destination = this.target.position + new Vector3(rnd.x, 0f, rnd.y);
		}
		data.enemyTeam.spawnSize = 0;
	}
}

public class EnemyStance
{
	public enum Stance
	{
		moreTanks,
		moreDestroyers,
		equalChance,
		random,
		airOnly,
		groundOnly

	}

	public static int GetResponse(string enemyType, Stance stance)
	{
		switch(stance)
		{
			case Stance.moreTanks:
				if (enemyType == "Helicopter")
					return 4;//AA
				if(Random.value > 0.6f)
				{
					return Random.value > 0.7f ? 2 : 3;
				}
				return 1;
			case Stance.moreDestroyers:
				if (enemyType == "Helicopter")
					return 4;//AA
				if (Random.value > 0.6f)
				{
					return Random.value > 0.7f ? 1 : 3;
				}
				return 2;
			case Stance.equalChance:
				if (enemyType == "Helicopter")
					return 4;//AA
				return Random.Range(1, 4);
			case Stance.airOnly:
				return 3;
			case Stance.groundOnly:
				if (enemyType == "Helicopter")
					return 4;//AA
				return Random.Range(1, 3);
			case Stance.random:
			default:
				return Random.Range(1, 5);
		}
	}
}
