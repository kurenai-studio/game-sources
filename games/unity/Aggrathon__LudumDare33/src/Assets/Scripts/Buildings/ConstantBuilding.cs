using UnityEngine;
using System.Collections;

public class ConstantBuilding : MonoBehaviour {

	private static bool isQuitting = false;

	public enum Constant {
		housing,
		guards,
		reputation
	}

	public Constant type;
	public int amount;

	void Start () {
		switch(type) {
		case Constant.housing:
			Data.housing += amount;
			break;
		case Constant.guards:
			Data.guards += amount;
			break;
		case Constant.reputation:
			Data.reputation.amount += amount;
			break;
		}
	}

	void OnDisable() {
		if(isQuitting)
			return;
		switch(type) {
		case Constant.housing:
			Data.housing -= amount;
			UserInterface.DrawStats();
			break;
		case Constant.guards:
			Data.guards -= amount;
			UserInterface.DrawStats();
			break;
		case Constant.reputation:
			Data.reputation.amount -= amount;
			UserInterface.DrawStats();
			break;
		}
	}

	void OnApplicationQuit() {
		isQuitting = true;
	}
}
