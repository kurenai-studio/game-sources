using UnityEngine;
using System.Collections.Generic;

public class GameData : MonoBehaviour {

	public static GameData instance { get; protected set; }
	public Color playerColor { get { return playerTeam.material.color; } }

	[Header("Teams")]
	public Team playerTeam;
	public Team enemyTeam;

	public float reinforcementTimer = 2f;
	float reinforcementTime = 0f;

	[Header("Progress")]
	public float progress;
	public int ticker { get { return playerTeam.tickerUnits.Count - enemyTeam.tickerUnits.Count; } }
	public float tickSpeed = 0.01f;

	[Header("Units")]
	public UnitTypeList unitTypes;

	void Awake()
	{
		instance = this;
		unitTypes.BuildDictionary();
		if(playerTeam.spawnPoint == null || enemyTeam.spawnPoint == null)
		{
			GameObject[] pts = GameObject.FindGameObjectsWithTag("Respawn");
			playerTeam.spawnPoint = pts[0].transform;
			enemyTeam.spawnPoint = pts[1].transform;
		}
	}

	void Update()
	{
		if (ticker != 0)
		{
			progress = Mathf.Clamp(progress + tickSpeed * ticker * Time.deltaTime, -1f, 1f);
		}
		else if (progress != 0)
		{
			if(progress > 0)
			{
				progress -= tickSpeed * 2 * Time.deltaTime;
				if (progress < 0f)
					progress = 0f;
			}
			else
			{
				progress += tickSpeed * 2 * Time.deltaTime;
				if (progress > 0f)
					progress = 0f;
			}
		}

		reinforcementTime += Time.deltaTime;
		if(reinforcementTime >  reinforcementTimer)
		{
			reinforcementTime -= reinforcementTimer;
			playerTeam.spawnSize++;
			enemyTeam.spawnSize++;
		}
	}
}

[System.Serializable]
public class Team
{
	public Transform spawnPoint;
	public int spawnSize;
	public Material material;
	public bool autoSelect;
	[System.NonSerialized]
	public List<Unit> selectedUnits;
	[System.NonSerialized]
	public LinkedList<Unit> sightedEnemies;
	[System.NonSerialized]
	public HashSet<Unit> tickerUnits;

	public Team()
	{
		selectedUnits = new List<Unit>();
		sightedEnemies = new LinkedList<Unit>();
		tickerUnits = new HashSet<Unit>();
	}
}
