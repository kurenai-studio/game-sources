using UnityEngine;
using UnityEngine.UI;

public class Progress : MonoBehaviour {

	GameData data;
	Image img;

	void Start () {
		data = GameData.instance;
		img = GetComponent<Image>();
	}
	
	void Update () {
		if(data.progress < 0)
		{
			img.fillAmount = -data.progress;
			img.fillClockwise = true;
			img.color = data.enemyTeam.material.color;
		}
		else
		{
			img.fillAmount = data.progress;
			img.fillClockwise = false;
			img.color = data.playerTeam.material.color;
		}
	}
}
