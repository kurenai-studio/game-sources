using UnityEngine;
using UnityEngine.UI;

public class SpawnSize : MonoBehaviour {

	GameData data;
	Text text;

	void Start () {
		data = GameData.instance;
		text = GetComponent<Text>();
	}
	
	void Update () {
		text.text = data.playerTeam.spawnSize.ToString();
	}
}
