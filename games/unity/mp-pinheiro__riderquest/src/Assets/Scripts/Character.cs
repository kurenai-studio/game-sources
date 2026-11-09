using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Character {
	string name;
	int damage;
	int maxHp;
	int hp;

	public Character(string name, int damage, int hp){
		this.name = name;
		this.damage = damage;
		this.hp = hp;
		//TODO other stats
	}

	public int Attack(Character target){
		target.hp -= damage;
		return damage;
	}

	public string GetName(){
		return name;
	}

	public bool IsDead(){
		return hp<=0;
	}
}
