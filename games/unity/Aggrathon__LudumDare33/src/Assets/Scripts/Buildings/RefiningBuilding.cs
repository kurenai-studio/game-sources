using UnityEngine;
using System.Collections;

public class RefiningBuilding : MonoBehaviour, IBuilding {

	public Refiner[] production;

	void Start () {
		Data.AddBuilding(this);
	}

	public void Work() {
		foreach(Refiner p in production) {
			//Debug.Log("Refining: "+p.resource.product);
			if(p.season == Data.Seasons.EverySeason || p.season == Data.season) {
				//Debug.Log("Right season");
				bool prod = false;
				if(p.resource.isFinishedGoods) {
					if(Data.ConsumeGoods(p.resource.product, p.resource.amount))
						prod = true;
				} else {
					if(Data.ConsumeResource(p.resource.product, p.resource.amount))
						prod = true;
				}
				//Debug.Log("Resource exists "+prod);
				if(prod) {
					if(p.product.isFinishedGoods)
						Data.AddGoods(p.product.product, p.product.amount);
					else
						Data.AddResource(p.product.product, p.product.amount);
				}
			} 
		}
	}
}
[System.Serializable]
public class Refiner : Producer {
	public Product resource;
}
