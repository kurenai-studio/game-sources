using UnityEngine;
using UnityEngine.UI;

public class Upgrade : MonoBehaviour
{

	public Trade trade;

	public Text optionLeft;
	public Text optionRight;

	private int option1 = 0;
	private int option2 = 1;
	private UpgradeOption[] options = new UpgradeOption[] {
		new UpgradeOption("Engine", 5, trade => trade.ship.acceleration *= 1.3f ),
		new UpgradeOption("Turning Thrusters", 5, trade => trade.ship.turnRate *= 1.3f ),
		new UpgradeOption("Shield Recharge", 3, trade => trade.ship.shieldCooldown *= 0.7f ),
		new UpgradeOption("Shield Duration", 1, trade => trade.ship.shieldDuration *= 1.2f ),
		new UpgradeOption("Missile Speed", 2, trade => trade.ship.missileSpeed *= 1.3f ),
		new UpgradeOption("Missile Loader", 4, trade => trade.ship.missileCooldown *= 0.7f ),
		new UpgradeOption("Cargo Packer", 6, trade => { trade.ship.maxCargo = (int)(trade.ship.maxCargo*1.8); trade.ship.shipStats.setCargo((float)trade.ship.currentCargo/(float)trade.ship.maxCargo); } ),
		new UpgradeOption("Reinforced Hulls", 3, trade => { trade.ship.maxHealth++; trade.ship.currentHealth++; trade.ship.shipStats.setHealth((float)trade.ship.currentHealth/(float)trade.ship.maxHealth); } ),
		new UpgradeOption("Maximum Food", 3, trade => { trade.ship.currentFood += trade.ship.maxCargo-trade.ship.currentCargo; trade.ship.shipStats.setCargo(1f); } ),
		new UpgradeOption("Maximum Products", 3, trade => { trade.ship.currentProducts += trade.ship.maxCargo-trade.ship.currentCargo; trade.ship.shipStats.setCargo(1f); } ),
		new UpgradeOption("Maximum Travellers", 3, trade => { trade.ship.currentPopulation += trade.ship.maxCargo-trade.ship.currentCargo; trade.ship.shipStats.setCargo(1f); } )
	};
	private int maxOptionChance;

	void Awake()
	{
		maxOptionChance = 0;
		for (int i = 0; i < options.Length; i++)
		{
			maxOptionChance += options[i].chance;
		}
	}

	public void OnEnable()
	{

		optionLeft.text = options[option1].name;
		optionRight.text = options[option2].name;
	}

	public void Update()
	{
		if (Input.GetButtonUp("Left"))
		{
			SelectLeft();
			return;
		}
		if (Input.GetButtonUp("Right"))
		{
			SelectRight();
			return;
		}
	}

	public void SelectLeft()
	{
		options[option1].action(trade);
		Return();
	}
	public void SelectRight()
	{
		options[option2].action(trade);
		Return();
	}

	void Return()
	{
		gameObject.SetActive(false);
		trade.gameObject.SetActive(true);

		AudioController.Upgrade();

		option1 = Random.Range(0, maxOptionChance);
		for (int i = 0; i < options.Length; i++)
		{
			if(options[i].chance > option1)
			{
				option1 = i;
			}
			else
			{
				option1 -= options[i].chance;
            }
		}
		option2 = Random.Range(0, maxOptionChance);
		for (int i = 0; i < options.Length; i++)
		{
			if (options[i].chance > option2)
			{
				option2 = i;
				return;
			}
			else
			{
				option2 -= options[i].chance;
			}
		}
	}

	class UpgradeOption
	{
		public delegate void Action(Trade t);
		public string name;
		public int chance;
		public Action action;

		public UpgradeOption(string name, int chance, Action action)
		{
			this.name = name;
			this.chance = chance;
			this.action = action;
		}
	}
}
