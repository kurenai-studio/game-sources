using UnityEngine;
using UnityEngine.UI;
using System.Collections;

public class Trade : MonoBehaviour
{

	private float counter;
	private bool leftLock;
	private bool rightLock;

	public Text shipPopulation;
	public Text shipFood;
	public Text shipProducts;

	public Text shipText;
	public Text planetText;

	public Text planetPopulation;
	public Text planetFood;
	public Text planetProducts;

	[Header("Trade")]
	public Ship ship;
	public Planet planet;
	public GameObject upgrade;

	void Update()
	{
		if (leftLock)
		{
			leftLock = Input.GetButton("Left");
		}
		else if (Input.GetButtonUp("Left"))
		{
			LoadCargo();
			return;
		}
		if (rightLock)
		{
			rightLock = Input.GetButton("Right");
		}
		else if (Input.GetButtonUp("Right"))
		{
			UnloadCargo();
			return;
		}
		if (Input.GetButton("Left") && Input.GetButton("Right"))
		{
			if (Input.GetButtonDown("Left") || Input.GetButtonDown("Right"))
			{
				Leave();
				return;
			}
		}
		if (Input.GetButtonUp("Cancel"))
		{
			Leave();
			return;
		}

		counter += Time.deltaTime;
		if (counter > Planet.PRODUCTION_INTERVAL)
		{
			counter -= Planet.PRODUCTION_INTERVAL;
			SetStats();
		}
	}

	public void UnloadCargo()
	{
		int food = Mathf.Min(ship.currentFood, planet.foodDemand - planet.food);
		if (food > 0)
		{
			ship.currentFood -= food;
			planet.food += food;
		}

		int pop = Mathf.Min(ship.currentPopulation, planet.populationDemand - planet.population);
		if (pop > 0)
		{
			ship.currentPopulation -= pop;
			planet.population += pop;
		}

		int prod = Mathf.Min(ship.currentProducts, planet.productDemand - planet.products);
		if (prod > 0)
		{
			ship.currentProducts -= prod;
			planet.products += prod;
		}
		bool upgrade = planet.TryLevelUp();
		ship.shipStats.setCargo((float)ship.currentCargo / (float)ship.maxCargo);
		if (upgrade)
		{
			ship.currentHealth = Mathf.Min(ship.currentHealth + 1, ship.maxHealth);
			ship.shipStats.setHealth((float)ship.currentHealth / (float)ship.maxHealth);
			this.upgrade.SetActive(true);
			gameObject.SetActive(false);
		}
		SetStats();
	}

	public void LoadCargo()
	{
		switch (planet.productionType)
		{
			case Planet.ProductionType.Food:
				int food = Mathf.Min(ship.maxCargo - ship.currentCargo, planet.food);
				ship.currentFood += food;
				planet.food -= food;
				break;
			case Planet.ProductionType.Population:
				int pop = Mathf.Min(ship.maxCargo - ship.currentCargo, planet.population);
				ship.currentPopulation += pop;
				planet.population -= pop;
				break;
			case Planet.ProductionType.Products:
				int prod = Mathf.Min(ship.maxCargo - ship.currentCargo, planet.products);
				ship.currentProducts += prod;
				planet.products -= prod;
				break;
		}

		SetStats();
		ship.shipStats.setCargo((float)ship.currentCargo / (float)ship.maxCargo);
	}

	public void SetStats()
	{
		shipFood.text = ship.currentFood.ToString();
		shipProducts.text = ship.currentProducts.ToString();
		shipPopulation.text = ship.currentPopulation.ToString();

		shipText.text = "Cargo: " + ship.currentCargo + " / " + ship.maxCargo;
		planetText.text = "Level: " + planet.level;

		planetFood.text = planet.food + " / " + planet.foodDemand;
		planetPopulation.text = planet.population + " / " + planet.populationDemand;
		planetProducts.text = planet.products + " / " + planet.productDemand;

		switch (planet.productionType)
		{
			case Planet.ProductionType.Food:
				planetFood.text += "  (+" + planet.productionAmount + ")";
				break;
			case Planet.ProductionType.Products:
				planetProducts.text += "  (+" + planet.productionAmount + ")";
				break;
			case Planet.ProductionType.Population:
				planetPopulation.text += "  (+" + planet.productionAmount + ")";
				break;
		}
	}

	public void Leave()
	{
		ship.transform.parent = null;
		Rigidbody2D rig = ship.GetComponent<Rigidbody2D>();
		Vector3 dist = (ship.transform.position - planet.transform.position).normalized * 5;
		ship.transform.position += dist;
		Vector2 dist2 = new Vector2(dist.x * 6, dist.y * 6);

		ship.gameObject.SetActive(true);
		rig.velocity = planet.GetComponent<Rigidbody2D>().velocity + dist2;
		rig.rotation += Vector2.Angle(Vector2.up, dist2);
		gameObject.SetActive(false);
	}

	public void OpenTrade(Ship ship, Planet planet)
	{
		this.ship = ship;
		this.planet = planet;
		gameObject.SetActive(true);
		ship.gameObject.SetActive(false);
		ship.transform.parent = planet.transform;
	}

	public void OnEnable()
	{
		leftLock = Input.GetButton("Left");
		rightLock = Input.GetButton("Right");
		SetStats();
	}
}
