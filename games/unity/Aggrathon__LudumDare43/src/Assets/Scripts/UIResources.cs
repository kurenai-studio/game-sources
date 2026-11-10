using UnityEngine;
using System.Collections;
using TMPro;
using System.Collections.Generic;

public class UIResources : MonoBehaviour
{
	public State player;
	[Header("UI")]
	public TextMeshProUGUI people;
	public TextMeshProUGUI miners;
	public TextMeshProUGUI farmers;
	public TextMeshProUGUI warriors;
	public TextMeshProUGUI prisoners;
	public TextMeshProUGUI gold;
	public TextMeshProUGUI food;

	Dictionary<int, string> stringCache;

	private void Start()
	{
		stringCache = new Dictionary<int, string>();
	}

	void Update()
	{
		people.text = stringCache.GetString(player.people);
		miners.text = stringCache.GetString(player.miners);
		farmers.text = stringCache.GetString(player.farmers);
		warriors.text = stringCache.GetString(player.warriors);
		prisoners.text = stringCache.GetString(player.prisoners);
		gold.text = stringCache.GetString(Mathf.FloorToInt(player.gold));
		food.text = stringCache.GetString(Mathf.FloorToInt(player.food));
	}

	public void IncreaseMiners()
	{
		if (player.people > 100)
		{
			player.people -= 100;
			player.miners += 100;
		}
		else if (player.people > 10)
		{
			player.people -= 10;
			player.miners += 10;
		}
		else
		{
			player.miners += player.people;
			player.people = 0;
		}
	}
	public void IncreaseFarmers()
	{
		if (player.people > 100)
		{
			player.people -= 100;
			player.farmers += 100;
		}
		else if (player.people > 10)
		{
			player.people -= 10;
			player.farmers += 10;
		}
		else
		{
			player.farmers += player.people;
			player.people = 0;
		}
	}
	public void IncreaseWarriors()
	{
		int delta = player.people;
		delta = Mathf.Min(delta, Mathf.FloorToInt(player.gold / player.goldCost));
		delta = Mathf.Min(delta, Mathf.FloorToInt(player.food / player.foodCost));
		if (delta > 0)
		{
			if (player.people > 10)
			{
				if (player.people > 100)
					delta = Mathf.Min(delta, 100);
				else
					delta = Mathf.Min(delta, 10);
			}
			player.people -= delta;
			player.warriors += delta;
			player.gold -= delta * player.goldCost;
			player.food -= delta * player.foodCost;
		}
	}
}

public static class StringDict {

	public static string GetString(this Dictionary<int, string> dict, int integer) {
		string tmp;
		if (dict.TryGetValue(integer, out tmp))
			return tmp;
		tmp = integer.ToString();
		dict[integer] = tmp;
		return tmp;
	}
}
