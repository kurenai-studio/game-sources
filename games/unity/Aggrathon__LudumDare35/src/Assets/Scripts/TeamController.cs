using UnityEngine;
using UnityEngine.EventSystems;
using System.Collections.Generic;

public class TeamController : MonoBehaviour {

	GameData data;
	Vector3 startSelection;
	bool selecting;

	public float unitSpace = 1f;
	public float commandRadius = 7f;

	void Start()
	{
		data = GameData.instance;
	}

	void Update()
	{
		if(Input.GetMouseButtonUp(1))
		{
			RaycastHit hit;
			if (Physics.Raycast(Camera.main.ScreenPointToRay(Input.mousePosition), out hit))
			{
				for (int i = 0; i < data.playerTeam.selectedUnits.Count; i++)
				{
					Vector3 rnd = Random.insideUnitSphere;
					rnd.y = 0f;
					rnd *= data.playerTeam.selectedUnits.Count > 1 ? commandRadius* data.playerTeam.selectedUnits.Count/10f : 0;
					data.playerTeam.selectedUnits[i].destination = hit.point+rnd;
				}
			}
		}
		else if (Input.GetMouseButtonUp(0) && selecting)
		{
			RaycastHit hit;
			if (Physics.Raycast(Camera.main.ScreenPointToRay(Input.mousePosition), out hit))
			{
				if (!Input.GetButton("Add to Selection"))
				{
					for (int i = 0; i < data.playerTeam.selectedUnits.Count; i++)
					{
						data.playerTeam.selectedUnits[i].selectionMarker.SetActive(false);
					}
					data.playerTeam.selectedUnits.Clear();
				}

				Vector3 end = hit.point;
				if (end.y > startSelection.y)
					end.y += 100f;
				else
					startSelection.y += 100f;
				Vector3 center = new Vector3((end.x + startSelection.x) * 0.5f, (end.y + startSelection.y) * 0.5f, (end.z + startSelection.z) * 0.5f);
				Vector3 half = new Vector3(Mathf.Abs(end.x - startSelection.x) * 0.5f, Mathf.Abs(end.y - startSelection.y) * 0.5f, Mathf.Abs(end.z - startSelection.z) * 0.5f);
				Collider[] cols = Physics.OverlapBox(center, half);

				for (int i = 0; i < cols.Length; i++)
				{
					Unit u = cols[i].transform.GetComponent<Unit>();
					if (u != null && u.team == data.playerTeam)
					{
						u.selectionMarker.SetActive(true);
						data.playerTeam.selectedUnits.Add(u);
					}
				}
			}
			selecting = false;
		}
		else if (Input.GetMouseButtonDown(0))
		{
			selecting = !EventSystem.current.IsPointerOverGameObject();
			if (selecting)
			{
				RaycastHit hit;
				if (Physics.Raycast(Camera.main.ScreenPointToRay(Input.mousePosition), out hit))
				{
					startSelection = hit.point;
				}
			}
		}
	}

	public void SpawnTeam()
	{
		int spawnSize = data.playerTeam.spawnSize;
		if (spawnSize == 0)
			return;

		Transform orig = data.playerTeam.spawnPoint;
		// b = % 2 pi r  =>  r = b /(% 2 pi)  => r = size / (1/num * 2 * pi) => r = num * size /(2 pi)
		float rad = spawnSize > 1 ? spawnSize * unitSpace * 0.5f / Mathf.PI : 0f;
		GameObject prefab = data.unitTypes.units[0];

		for (int i = 0; i < data.playerTeam.selectedUnits.Count; i++)
		{
			data.playerTeam.selectedUnits[i].selectionMarker.SetActive(false);
		}
		data.playerTeam.selectedUnits.Clear();

		for (int i = 0; i < spawnSize; i++)
		{
			GameObject go = GameObjectPool.Get(prefab);
			go.transform.position = orig.position + Quaternion.AngleAxis(360f / spawnSize * i, orig.up) * Vector3.forward * rad;
			go.transform.rotation = orig.rotation;
			go.GetComponent<Unit>().Spawn(data.playerTeam, prefab);
		}
		data.playerTeam.spawnSize = 0;
	}
	
	public void Shapeshift(int num)
	{
		Unit[] us = new Unit[data.playerTeam.selectedUnits.Count];
		for (int i = 0; i < data.playerTeam.selectedUnits.Count; i++)
		{
			us[i] = data.playerTeam.selectedUnits[i];
		}
		for (int i = 0; i < us.Length; i++)
		{
			us[i].Shapeshift(data.unitTypes.units[num]);
		}
	}
}
