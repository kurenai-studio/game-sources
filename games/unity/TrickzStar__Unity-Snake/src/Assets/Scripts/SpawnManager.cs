using System.Collections.Generic;
using UnityEngine;

public class SpawnManager : MonoBehaviour
{

	private static SpawnManager instance;

	public static SpawnManager Instance
	{
		get
		{
			if(instance == null)
			{
				instance = new SpawnManager();
			}

			return instance;
		}
	}

	public Fruit prefab;

	public Transform border_left;
	public Transform border_right;
	public Transform border_top;
	public Transform border_bottom;

	private List<Fruit> fruits;

	// Start is called before the first frame update
    void Start()
    {
		instance = this;
		fruits = new List<Fruit>();

		for(int i = 0; i < 5; i++)
		{
			Vector3 position = new Vector3(Random.Range(-2.5f, 2.5f), 
				Random.Range(-4.5f, 4.5f), 0);

			Fruit fruit = Instantiate(prefab, position, Quaternion.identity);
			fruits.Add(fruit);
		}
    }

    // Update is called once per frame
    void Update()
    {
		GenerateFruits();
    }

	void GenerateFruits()
	{
		if(fruits.Count < 5)
		{
			Vector3 position = new Vector3(Random.Range(-2.5f, 2.5f),
				Random.Range(-4.5f, 4.5f), 0);

			Fruit fruit = Instantiate(prefab, position, Quaternion.identity);
			fruits.Add(fruit);
		}
	}

	public void RemoveFromList(Fruit fruitObj)
	{
		fruits.Remove(fruitObj);
	}
}
