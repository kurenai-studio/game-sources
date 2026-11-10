using UnityEngine;
using System.Collections.Generic;

public class PlanetarySystem : MonoBehaviour
{
	public int enemyTreshold = 5;
	public float enemyScaling = 0.3f;
	public float enemyMaxSpawnDistance = 1000f;
	public GameObject enemyPrefab;


	private Rigidbody2D[] bodies = new Rigidbody2D[] { };
	private List<Rigidbody2D> tempBodies = new List<Rigidbody2D>();
	private List<Rigidbody2D> pirates = new List<Rigidbody2D>();

	void FixedUpdate () {
		for(int i = 0; i < bodies.Length; i++)
		{
			for (int j = i+1; j < bodies.Length; j++)
			{
				Vector2 force = PhysicsFunctions.GravityForce(bodies[i], bodies[j]);
				bodies[i].AddForce(-force);
				bodies[j].AddForce(force);
			}
			for (int k = 0; k < tempBodies.Count; k++)
			{
				Vector2 force = PhysicsFunctions.GravityForce(bodies[i], tempBodies[k]);
				tempBodies[k].AddForce(force);
			}
			for (int l = 0; l < pirates.Count; l++)
			{
				Vector2 force = PhysicsFunctions.GravityForce(bodies[i], pirates[l]);
				pirates[l].AddForce(force);
			}
		}
	}

	#region data getters

	public Vector2 centerOfMass { get
		{
			Vector2 center = new Vector2(0f, 0f);
			float mass = totalMass;
			for (int i = 0; i < bodies.Length; i++)
			{
				center += (bodies[i].mass / mass) * bodies[i].position;
			}
			return center;
		} }

	public float totalMass { get; protected set; }

	#endregion

	#region registers
	public void registerConstantBody(Rigidbody2D rigid)
	{
		Rigidbody2D[] newbod = new Rigidbody2D[bodies.Length + 1];
		int i;
        for (i = 0; i<bodies.Length; i++)
		{
			newbod[i] = bodies[i];
		}
		newbod[i] = rigid;
		bodies = newbod;

		totalMass += rigid.mass;
	}

	public void registerTempBody(Rigidbody2D bod)
	{
		tempBodies.Add(bod);
		if(bod.gameObject.tag == "Player")
		{
			var en = GetComponentsInChildren<WarpGate>().GetEnumerator();
			while(en.MoveNext())
			{
				((WarpGate)en.Current).SpawnLoopers();
			}
			var en2 = pirates.GetEnumerator();
			while(en2.MoveNext())
			{
				(en2.Current.GetComponent<Pirate>()).SetTarget(bod);
			}
		}
	}

	public void unregisterTempBody(Rigidbody2D bod)
	{
		tempBodies.Remove(bod);
		if (bod.gameObject.tag == "Player")
		{
			var en = GetComponentsInChildren<WarpGate>().GetEnumerator();
			while (en.MoveNext())
			{
				((WarpGate)en.Current).DespawnLoopers();
			}
			var en2 = pirates.GetEnumerator();
			while (en2.MoveNext())
			{
				(en2.Current.GetComponent<Pirate>()).SetTarget(null);
			}
		}
	}

	public void registerPirate(Rigidbody2D bod)
	{
		pirates.Add(bod);
	}

	public void unregisterPirate(Rigidbody2D bod)
	{
		pirates.Remove(bod);
	}
	#endregion

	public void SpawnEnemies()
	{
		if(enemyTreshold <= Planet.numUpgrades)
		{
			Quest.instance.Pirates();
			for (int i = 0; i < (Planet.numUpgrades-enemyTreshold)*enemyScaling; i++)
			{
				GameObject go = ObjectPool.GetObject(enemyPrefab);
				Vector2 trans = transform.position;
				Vector2 pos = Random.insideUnitCircle * Random.Range(200f, enemyMaxSpawnDistance)+trans;
				while (Physics2D.OverlapCircle(pos, 100f) != null)
				{
					pos = Random.insideUnitCircle * Random.Range(200f, enemyMaxSpawnDistance) + trans;
				}
				go.transform.position = pos;
				Pirate p = go.GetComponent<Pirate>();
				p.SetSolarSystem(this);
				p.SetTarget(null);
			}
		}
	}


	public void OnDrawGizmos()
	{
		Gizmos.color = Color.red;
		for (int i = 0; i < 360; i += 10)
		{
			Gizmos.DrawLine(
				transform.position + new Vector3(Mathf.Cos(i * Mathf.Deg2Rad) * enemyMaxSpawnDistance, Mathf.Sin(i * Mathf.Deg2Rad) * enemyMaxSpawnDistance, 0),
				transform.position + new Vector3(Mathf.Cos((i + 10) * Mathf.Deg2Rad) * enemyMaxSpawnDistance, Mathf.Sin((i + 10) * Mathf.Deg2Rad) * enemyMaxSpawnDistance, 0)
				);
		}
	}
}
