using UnityEngine;
using UnityEngine.UI;

public class TradeWindow : MonoBehaviour {

	public Text tradeText;
	public RectTransform buttonParent;

	private Trader currentTrader;

	void Start () {
		gameObject.SetActive(false);
	}

	public void Show(Trader trader) {
		currentTrader = trader;

		
		if(buttonParent.childCount < trader.possibleTrades.tradeList.Count) {
			Debug.LogError("[TRADEWINDOW] Too few buttons in the tradewindow");
			return;
		}
		
		int i = 0;
		foreach (Transform child in buttonParent) {
			if(i < trader.possibleTrades.tradeList.Count) {
				child.gameObject.SetActive(true);
				child.GetChild(0).GetComponent<Text>().text = trader.possibleTrades.tradeList[i].item;
			} else {
				child.gameObject.SetActive(false);
			}
			i++;
		}
		
		transform.position = trader.transform.position;
		SetTradeAmount(trader.currentTradeAmount);
		gameObject.SetActive(true);
	}

	public void SetTradeAmount(float value) {
		int v = Mathf.Clamp((int)value, -10, 10);
		currentTrader.currentTradeAmount = v;
		if (v < 0) {
			tradeText.text = "Sells "+(-v)+"x "+currentTrader.currentTradeItem.item+" for "+currentTrader.currentTradeValue+" Gold";
		} else {
			tradeText.text = "Buys "+v+"x "+currentTrader.currentTradeItem.item+" for "+(-currentTrader.currentTradeValue)+" Gold";
		}
	}

	public void SetTradeItem(int index) {
		currentTrader.currentTradeItem = currentTrader.possibleTrades.tradeList[index];
		SetTradeAmount(currentTrader.currentTradeAmount);
	}
}
