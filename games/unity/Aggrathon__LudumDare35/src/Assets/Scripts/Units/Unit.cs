using UnityEngine;
using System.Collections;

public abstract class Unit : MonoBehaviour {

	public delegate void SightCallback(Unit unit, Unit enemy, bool first);

	public GameObject selectionMarker;
	public Renderer[] coloredMaterials;

	[System.NonSerialized]
	public UnitType type;
	public abstract Vector3 destination { get; set; }

	[System.NonSerialized]
	public Team team;
	[System.NonSerialized]
	public bool seen;
	[System.NonSerialized]
	public bool triggered;
	[System.NonSerialized]
	public float health;
	[System.NonSerialized]
	public Unit target;

	public SightCallback enemySighted;
	public SightCallback enemyLost;
	public SightCallback unitDied;

	public void Spawn (Team team, GameObject prefab) {
		this.team = team;
		type = UnitTypeList.dict[prefab];
		transform.parent = team.spawnPoint;
		destination = transform.position;
		health = type.health;
		seen = false;
		if(team.autoSelect)
		{
			selectionMarker.SetActive(true);
			team.selectedUnits.Add(this);
		}
		else
		{
			selectionMarker.SetActive(false);
		}
		if (coloredMaterials.Length == 0)
		{
			coloredMaterials = GetComponentsInChildren<Renderer>();
		}
		for (int i = 0; i < coloredMaterials.Length; i++)
		{
			coloredMaterials[i].material = team.material;
		}
		enemyLost = null;
		enemySighted = null;
		unitDied = null;
	}

	public bool Damage(float amount)
	{
		health -= amount;
		if(health < 1f)
		{
			if (unitDied != null) unitDied(this, this, false);
			Disable();
			return true;
		}
		return false;
	}

	public void Shapeshift(GameObject newUnit)
	{
		if(GetComponent<PoolObject>().prefab == newUnit)
		{
			return;
		}

		GameObject go = GameObjectPool.Get(newUnit);
		go.transform.position = transform.position;
		go.transform.rotation = transform.rotation;
		Unit u = go.GetComponent<Unit>();
		u.Spawn(team, newUnit);
		u.destination = destination;
		u.health = u.type.health * health / type.health;
		u.enemyLost = enemyLost;
		u.enemySighted = enemySighted;
		u.unitDied = unitDied;
		Disable();
	}

	void OnTriggerEnter(Collider other)
	{
		if (other.isTrigger)
			return;
		Unit u = other.GetComponent<Unit>();
		if (u != null && u.team != team)
		{
			if(enemySighted != null)
				enemySighted(this, u, u.seen);
			if(!u.seen)
			{
				u.seen = true;
				team.sightedEnemies.AddLast(u);
			}
		}
	}

	void OnTriggerExit(Collider other)
	{
		if (other.isTrigger)
			return;
		if (enemyLost != null)
		{
			Unit u = other.GetComponent<Unit>();
			if (u != null && u.team != team)
			{
				enemyLost(this, u, u.seen);
			}
		}
	}

	void Disable()
	{
		gameObject.SetActive(false);
		GameObject go = GameObjectPool.Get(type.disableParticles);
		go.transform.position = transform.position;
		go.transform.rotation = transform.rotation;
		ParticleSystem ps = go.GetComponentInChildren<ParticleSystem>();
		ps.startColor = team.material.color;
		ps.Stop();
		ps.Play();
	}

	void OnDisable()
	{
		team.selectedUnits.Remove(this);
		team.tickerUnits.Remove(this);
	}
}
