using UnityEngine;
using System.Collections;

public class ProducingBuilding : MonoBehaviour, IBuilding {

	public Producer[] production;

	void Start () {
		Data.AddBuilding(this);
	}

	public void Work() {
		foreach( Producer p in production) {
			if(p.season == Data.Seasons.EverySeason || p.season == Data.season) {
				if(p.product.isFinishedGoods)
					Data.AddGoods(p.product.product, p.product.amount);
				else
					Data.AddResource(p.product.product, p.product.amount);
			} 
		}
	}
}
[System.Serializable]
public class Producer {
	public Data.Seasons season;
	public Product product;

	[System.Serializable]
	public class Product {
		public string product;
		public int amount;
		public bool isFinishedGoods;
	}
}
