using UnityEngine;
using System.Collections;
using System;
using TMPro;

[RequireComponent(typeof(LineRenderer))]
public class Army : MonoBehaviour, IBattleParticipant
{
	[NonSerialized] public State state;
	[NonSerialized] public int size;
	[NonSerialized] public State target;
	[NonSerialized] public float morale;
	[NonSerialized] public int prisoners;
	[NonSerialized] public int gold;
	public float speed = 2f;
	public float minDistance = 0.5f;
	public Battle battlePrefab;

	public Transform visual;
	public TextMeshPro text;

	LineRenderer lr;

	public Vector3 position
	{
		get
		{
			return transform.position;
		}
	}

	private void Awake()
	{
		lr = GetComponent<LineRenderer>();
		lr.positionCount = 2;
	}

	private void Update()
	{
		Vector3 dir = target.transform.position - transform.position;
		visual.rotation = Quaternion.Euler(0, 0, Mathf.Atan2(dir.y, dir.x) * Mathf.Rad2Deg - 90f);
		float len = Vector3.Magnitude(dir);
		if (len <= minDistance)
		{
			if (target == state)
			{
				state.people += size;
				state.gold += gold;
				state.prisoners += prisoners;
				size = 0;
				Destroy(gameObject);
			}
			else
			{
				Instantiate<Battle>(battlePrefab).Setup(this, target);
				gameObject.SetActive(false);
			}
		}
		else
		{
			float speed = this.speed * Time.deltaTime / len;
			transform.position += dir * speed;
			lr.SetPosition(1, transform.position);
			lr.SetPosition(0, target.transform.position);
		}
	}

	public void Setup(State state, int size, State target)
	{
		transform.position = state.transform.position;
		lr.SetPosition(0, transform.position);
		lr.SetPosition(1, target.transform.position);
		this.state = state;
		this.size = size;
		this.target = target;
		morale = size;
		prisoners = 0;
		gold = 0;
		text.text = size.ToString();
	}

	public float GetMorale()
	{
		return morale;
	}

	public int GetDamage()
	{
		float damage = size * state.armyDamage;
		prisoners += Mathf.FloorToInt(damage * state.armyCapture);
		return Mathf.CeilToInt(damage);
	}

	public bool DoDamage(int damage)
	{
		morale -= damage / state.armyMorale;
		size = Mathf.Max(0, size-damage);
		return morale > 0;
	}

	public virtual void EndCombat(bool won)
	{
		if (won)
		{
			int pris = Mathf.FloorToInt(target.people * state.armyCapture);
			target.people -= pris;
			prisoners += pris;
			pris = Mathf.FloorToInt(target.miners * state.armyCapture);
			target.miners -= pris;
			prisoners += pris;
			pris = Mathf.FloorToInt(target.farmers * state.armyCapture);
			target.farmers -= pris;
			prisoners += pris;
			pris = Mathf.FloorToInt(target.prisoners * state.armyCapture);
			target.prisoners -= pris;
			prisoners += pris;
			pris = Mathf.FloorToInt(target.gold * state.armyCapture);
			target.gold -= pris;
			gold += pris;
		}
		else
		{
			state.aiMilitarySize += state.aiMilitarySize/10;
		}
		prisoners = Mathf.Min(size * 2, prisoners);
		gold = Mathf.Min(gold, prisoners);
		target = state;
		text.text = size.ToString();
		gameObject.SetActive(true);
	}
}
