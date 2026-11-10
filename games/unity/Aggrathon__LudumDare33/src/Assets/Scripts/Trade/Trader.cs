using UnityEngine;
using System.Collections;

public class Trader : MonoBehaviour, IBuilding {

	public TradeList possibleTrades;

	public int currentTradeAmount = 0;
	public TradeItem currentTradeItem {
		get {return currTradeItem;}
		set {currTradeItem = value;}
	}

	private TradeItem currTradeItem;

	public int currentTradeValue {
		get { return currentTradeItem.TransactionValue(currentTradeAmount); }
	}

	void Start () {
		Data.AddBuilding(this);
		currTradeItem = possibleTrades.tradeList[0];
	}

	public void Work() {
		if(currentTradeAmount > 0) {
			Data.PayMoney(currentTradeValue);
			if(currentTradeItem.isFinishedGoods) {
				Data.AddGoods(currentTradeItem.item, currentTradeAmount);
			} else {
				Data.AddResource(currentTradeItem.item, currentTradeAmount);
			}
		} else {
			if(currentTradeItem.isFinishedGoods) {
				if(Data.ConsumeGoods(currentTradeItem.item, -currentTradeAmount))
					Data.GetMoney(currentTradeValue);
			} else {
				if(Data.ConsumeResource(currentTradeItem.item, -currentTradeAmount))
					Data.GetMoney(currentTradeValue);
			}
		}
	}

	void OnDestroy() {
		Data.RemoveBuilding(this);
	}

	public void ShowTradeWindow() {
		UserInterface.ShowTradeWindow(this);
	}
}
