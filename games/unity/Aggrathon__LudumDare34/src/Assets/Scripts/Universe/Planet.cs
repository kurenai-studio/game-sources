using UnityEngine;
using System.Collections;

public class Planet : GravityObject
{

	public enum ProductionType
	{
		Population,
		Food,
		Products
	}

	public const float PRODUCTION_INTERVAL = 1.5f;
	public static int numUpgrades { get; protected set; }

	[Header("Planet")]
	public bool antiClockWiseOrbit = false;
	[SerializeField]
	private int _level = 0;
	public int level { get { return _level; } set { _level = value; } } //Win condition number of total levels

	[Header("Production")]
	public ProductionType productionType;
	public int productionAmount = 5;
	public float productionCapMultiplier = 2.0f;

	[Header("Current")]
	public int population = 0;
	public int food = 0;
	public int products = 0;

	[Header("Demand")]
	public int populationDemand = 100;
	public int foodDemand = 100;
	public int productDemand = 100;
	public float demandScaling = 1.5f;

	public void Start()
	{
		PlanetarySystem solarSystem = transform.parent.GetComponent<PlanetarySystem>();
		Vector2 center = solarSystem.centerOfMass;
		Rigidbody2D rigidbody = GetComponent<Rigidbody2D>();

		bool rot = rigidbody.position.y < center.y;
		if (antiClockWiseOrbit) rot = !rot;
        rigidbody.velocity = PhysicsFunctions.OrbitalSpeed(center - rigidbody.position, solarSystem.totalMass, rot);

		StartCoroutine(Produce());
	}

	IEnumerator Produce()
	{
		WaitForSeconds wait = new WaitForSeconds(PRODUCTION_INTERVAL);
        while (true)
		{
			switch(productionType)
			{
				case ProductionType.Food:
					food = Mathf.Min(food + productionAmount, (int)(foodDemand * productionCapMultiplier));
					break;
				case ProductionType.Population:
					population = Mathf.Min(population + productionAmount, (int)(populationDemand * productionCapMultiplier));
					break;
				case ProductionType.Products:
					products = Mathf.Min(products + productionAmount, (int)(productDemand * productionCapMultiplier));
					break;
			}
			yield return wait;
		}
	}

	public bool TryLevelUp()
	{
		if (food >= foodDemand && products >= productDemand && population >= populationDemand)
		{
			food -= foodDemand;
			products -= productDemand;
			population -= populationDemand;
			level++;
			foodDemand = (int)(foodDemand * demandScaling);
			productDemand = (int)(productDemand * demandScaling);
			populationDemand = (int)(populationDemand * demandScaling);
			productionAmount++;

			numUpgrades++;
			Quest.instance.Grow(level);
			return true;
		}
		return false;
	}
}
