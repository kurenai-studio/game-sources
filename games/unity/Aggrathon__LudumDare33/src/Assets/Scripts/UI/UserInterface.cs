using UnityEngine;
using UnityEngine.UI;

public class UserInterface : MonoBehaviour {

	private static UserInterface instance;

	public BuildWindow buildWindow;
	public TradeWindow tradeWindow;
	public GameObject retryWindow;
	public GameObject winWindow;
	public Hunting feedWindow;

	public Text statText;
	public Text statValues;
	public Text statChange;

	void Awake () {
		instance = this;
	}

	void Start() {
		DrawStats();
	}

	public static void NextSeason() {
		Data.HideBuilders();
		instance.buildWindow.gameObject.SetActive(false);
		instance.tradeWindow.gameObject.SetActive(false);
		Data.NextSeason();
	}

	public static void ShowBuild() {
		Data.ShowBuilders();
	}

	public static void ShowBuildWindow(Builder builder) {
		instance.buildWindow.Show(builder);
	}
	
	public static void QuitApplication() {
		Application.Quit();
	}

	public static void ShowRestartWindow() {
		instance.retryWindow.SetActive(true);
	}

	public static void Restart() {
		Application.LoadLevel(Application.loadedLevel);
	}

	public static void Win() {
		instance.winWindow.SetActive(true);
	}

	public static void Feed() {
		instance.feedWindow.Show();
	}

	public static void ShowTradeWindow(Trader Trader) {
		instance.tradeWindow.Show(Trader);
	}

	public static void DrawStats() {
		string stats = "<b>Time</b>\n\tYear:\n\tSeason:\n";
		string values = "\n"+Data.year+"\n"+Data.season.ToString()+"\n";
		string change = "\n\n\n";

		stats += "<b>Town</b>\n";
		values += "\n";
		change += "\n";
		
		stats += "\tPopulation:\n";
		values += statMainFormat(Data.population.amount);
		change += statDeltaFormat(Data.population.delta);
		
		stats += "\tHousing:\n";
		values += statMainFormat(Data.housing);
		change += "\n";
		
		stats += "\tReputation:\n";
		values += statMainFormat(Data.reputation.amount);
		change += statDeltaFormat(Data.reputation.delta);
		
		stats += "\tCrime:\n";
		values += Data.crime.amount+"\n";
		change += statDeltaFormat(Data.crime.delta);
		
		stats += "\tGuards:\n";
		values += Data.guards+"\n";
		change += "\n";

		stats += "<b>Mayor</b>\n";
		values += "\n";
		change += "\n";
		
		stats += "\tGold:\n";
		values += statMainFormat(Data.money.amount);
		change += statDeltaFormat(Data.money.delta);
		
		stats += "\tStrength:\n";
		values += statMainFormat(Data.power.amount, 20);
		change += statDeltaFormat(Data.power.delta);
		
		stats += "<b>Goods</b>\n";
		values += "\n";
		change += "\n";
		foreach ( var kvp in Data.goods) {
			stats += "\t"+kvp.Key+":\n";
			values += statMainFormat(kvp.Value.amount);
			change += statDeltaFormat(kvp.Value.delta);
		}
		
		stats += "<b>Resources</b>\n";
		values += "\n";
		change += "\n";
		foreach ( var kvp in Data.resources) {
			stats += "\t"+kvp.Key+":\n";
			values += statMainFormat(kvp.Value.amount);
			change += statDeltaFormat(kvp.Value.delta);
		}

		instance.statText.text = stats;
		instance.statValues.text = values;
		instance.statChange.text = change;
		RectTransform par = instance.statText.transform.parent as RectTransform;
		par.sizeDelta = new Vector2(par.rect.width, instance.statText.preferredHeight+4);
	}
	private static string statDeltaFormat(int value) {
		if(value == 0)
			return "\n";
		if (value > 0)
			return "+"+value+"\n";
		else
			return value+"\n";
	}
	private static string statMainFormat(int value, int treshhold=1) {
		if(value < treshhold)
			return "<color=red>"+value+"</color>\n";
		else
			return value+"\n";
	}



	public void InstancedQuitApplication() {
		QuitApplication();
	}
	
	public void InstancedNextSeason() {
		NextSeason();
	}
	
	public void InstancedShowBuild() {
		ShowBuild();
	}
	
	public void InstancedFeed() {
		Feed();
	}
	
	public void InstancedRestart() {
		Restart();
	}

	public void InstancedDrawStats() {
		DrawStats();
	}
}
