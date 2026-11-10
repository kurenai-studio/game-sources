using UnityEngine;
using UnityEngine.UI;

public class PlayerColor : MonoBehaviour {
	
	void Start () {
		GetComponent<CanvasRenderer>().SetColor(GameData.instance.playerColor);
	}
}
