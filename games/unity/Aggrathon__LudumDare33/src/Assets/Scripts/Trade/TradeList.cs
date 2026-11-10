using UnityEngine;
using System.Collections.Generic;

public class TradeList : ScriptableObject {

	public List<TradeItem> tradeList;
}

[System.Serializable]
public class TradeItem {
	public string item;
	public int sellCost;
	public int buyCost;
	public bool isFinishedGoods;

	public TradeItem (string item, int sellCost, int buyCost, bool isFinishedGoods)
	{
		this.item = item;
		this.sellCost = sellCost;
		this.buyCost = buyCost;
		this.isFinishedGoods = isFinishedGoods;
	}
	

	public int TransactionValue(int amount) {
		if (amount < 0) {
			return -amount*sellCost;
		} else {
			return amount*buyCost;
		}
	}
}
