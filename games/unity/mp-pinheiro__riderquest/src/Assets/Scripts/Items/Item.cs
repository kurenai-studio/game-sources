using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public abstract class Item : MonoBehaviour {

	protected string name;

	public Item(string name){
		this.name = name;
	}

	public abstract void Start();
	
	public abstract void Update ();

	public abstract void Act(Character target);

	public string getName(){
		return name;
	}
}
