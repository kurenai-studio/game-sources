using UnityEngine;
using UnityEngine.UI;
using System.Collections;

[System.Serializable]
public class UnitType {

	[Header("Type")]
	public string name;
	public Sprite icon;
	[TextArea] public string description;
	public float health;
	public bool air = false;
	public GameObject disableParticles;
}
