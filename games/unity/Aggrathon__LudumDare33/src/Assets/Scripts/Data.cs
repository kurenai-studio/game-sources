using UnityEngine;
using System.Collections.Generic;

public class Data : MonoBehaviour {
	
	public const float TAX = 2f;
	public const float ROADRADIE = 100f;

	[System.Serializable]
	public class Item {
		public int amount;
		public int delta;

		public Item(int amount, int delta) {
			this.amount = amount;
			this.delta = delta;
		}

		public void Change(int amount) {
			this.amount += amount;
			this.delta += amount;
		}
	}

	public enum Seasons {
		EverySeason,
		Spring,
		Summer,
		Autumn,
		Winter
	}
	
	private static List<Builder> builders;
	private static List<Builder> lockedBuilders;
	private static List<IBuilding> buildings;
	private static List<Road> roads;

	private static List<IOnSeasonChange> seasonListeners;

	public static Seasons season;
	public static int year;
	public static Item population;
	public static int housing;
	public static Item reputation;
	public static Item crime;
	public static int guards;
	public static Item money;
	public static Item power;
	
	public static Dictionary<string, Item> goods;
	public static Dictionary<string, Item> resources;

	void Awake () {
		builders = new List<Builder>();
		lockedBuilders = new List<Builder>();
		buildings = new List<IBuilding>();
		roads = new List<Road>();
		seasonListeners = new List<IOnSeasonChange>();


		goods = new Dictionary<string, Item>();
		resources = new Dictionary<string, Item>();
		goods.Add("Food", new Item(50, 0));

		season = Seasons.Spring;
     	year = 0;
		population = new Item(0,0);
     	housing = 0;
		reputation = new Item(20, 0);
      	crime = new Item(0,0);
     	guards = 0;
		money = new Item(500,0);
      	power = new Item(80,0);
	}

	public static void AddBuilder(Builder b) {
		if(b.unlocked)
			builders.Add(b);
		else
			lockedBuilders.Add(b);
	}

	public static void RemoveBuilder(Builder b) {
		builders.Remove(b);
	}

	public static void HideBuilders() {
		foreach(Builder b in builders) {
			b.gameObject.SetActive(false);
		}
	}
	
	public static void ShowBuilders() {
		foreach(Builder b in builders) {
			b.gameObject.SetActive(true);
		}
	}

	public static void AddRoad(Road r) {
		roads.Add(r);
	}

	public static void RemoveRoad(Road r) {
		roads.Remove(r);
	}

	public static void ConstructionAt(Vector3 pos) {
		float sqr = ROADRADIE*ROADRADIE;
		for(int i = 0; i < roads.Count; i++) {
			if(Vector3.SqrMagnitude(pos-roads[i].transform.position) <sqr) {
				roads[i].gameObject.SetActive(true);
				for(int j = 0; j < lockedBuilders.Count; j++) {
					if(Vector3.SqrMagnitude(lockedBuilders[j].transform.position-roads[i].transform.position) < sqr) {
						lockedBuilders[j].unlocked = true;
						builders.Add(lockedBuilders[j]);
						lockedBuilders[j].gameObject.SetActive(true);
						lockedBuilders.RemoveAt(j);
						j--;
					}
				}
				roads.RemoveAt(i);
				i--;
			}
		}
	}
	
	public static void AddSeasonListener(IOnSeasonChange listn) {
		seasonListeners.Add(listn);
	}
	
	public static void RemoveSeasonListener(IOnSeasonChange listn) {
		seasonListeners.Remove(listn);
	}


	public static void PayMoney(int amount) {
		money.Change(-amount);
	}

	public static void GetMoney(int amount) {
		money.Change(amount);
	}
	
	public static void AddGoods(string type, int amount) {
		Item item = null;
		if(goods.TryGetValue(type, out item))
			item.Change(amount);
		else 
			goods.Add(type, new Item(amount, amount));
	}

	public static bool ConsumeGoods(string type, int amount) {
		Item item = null;
		if(!goods.TryGetValue(type, out item)) {
			goods.Add(type, new Item(0, 0));
			return false;
		}
		if(item.amount < amount)
			return false;
		item.Change(-amount);
		return true;
	}
	
	public static void AddResource(string type, int amount) {
		Item item = null;
		if(resources.TryGetValue(type, out item))
			item.Change(amount);
		else 
			resources.Add(type, new Item(amount, amount));
	}
	
	public static bool ConsumeResource(string type, int amount) {
		Item item = null;
		if(!resources.TryGetValue(type, out item)) {
			resources.Add(type, new Item(0, 0));
			return false;
		}
		if(item.amount < amount)
			return false;
		item.Change(-amount);
		return true;
	}


	public static void AddBuilding(IBuilding b) {
		buildings.Add(b);
	}
	
	public static void RemoveBuilding(IBuilding b) {
		buildings.Remove(b);
	}

	public static void NextSeason() {
		foreach(var kvp in goods) {
			Item i = kvp.Value;
			i.delta = 0;
		}
		foreach(var kvp in resources) {
			Item i = kvp.Value;
			i.delta = 0;
		}
		money.delta = 0;
		population.delta = 0;
		reputation.delta = 0;

		foreach(IBuilding b in buildings) {
			b.Work();
		}
		int pop10 = population.amount/10;
		ConsumeGoods("Food", population.amount/5);
		foreach(var kvp in goods) {
			if(kvp.Value.amount > pop10) {
				kvp.Value.Change(-pop10);
				reputation.Change(1);
			} else {
				reputation.Change(-1);
			}
		}


		reputation.amount = Mathf.Min(reputation.amount, 100);
		int newpop = Mathf.Min(reputation.amount, housing-population.amount);
		population.Change(newpop);
		GetMoney((int)(population.amount*TAX));
		PayMoney(guards*10);
		power.delta--;
		power.amount += power.delta;

		int newcrime = population.amount/20-guards;
		crime.delta = newcrime-crime.amount;
		crime.amount = newcrime;
		PayMoney(money.amount*newcrime/100);

		switch(season) {
		case Seasons.Spring:
			season = Seasons.Summer;
			break;
		case Seasons.Summer:
			season = Seasons.Autumn;
			break;
		case Seasons.Autumn:
			season = Seasons.Winter;
			break;
		case Seasons.Winter:
			season = Seasons.Spring;
			year++;
			break;
		}

		if(population.amount < 0 || power.amount < 1 || money.amount < 0) {
			UserInterface.ShowRestartWindow();
		}
		if(population.amount > 199 && power.amount > 99 && money.amount > 999) {
			UserInterface.Win();
		}

		foreach(IOnSeasonChange ls in seasonListeners) {
			ls.OnSeasonChange(season);
		}

		UserInterface.DrawStats();
	}

}
