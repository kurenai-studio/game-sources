using UnityEngine;
using UnityEngine.UI;

public class LoseExplanation : MonoBehaviour {

	void OnEnable() {
		string outp = "";
		if(Data.money.amount<0) {
			outp += " No Money ";
		}
		if(Data.power.amount<0) {
			outp += " No Strength ";
		}
		if(Data.population.amount<0) {
			outp += " No Population ";
		}
		GetComponent<Text>().text = outp;
	}
}
