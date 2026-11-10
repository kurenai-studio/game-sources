using UnityEngine;
using UnityEngine.UI;
using System.Collections;

public class ShipUI : MonoBehaviour {

	[Header("Meters")]
	public Slider health;
	public Slider cargo;
	public Slider missile;
	public Slider shield;

	public void setHealth(float currH)
	{
		health.value = currH;
	}

	public void setCargo(float currC)
	{
		cargo.value = currC;
	}

	public void setMissile(float currM)
	{
		missile.value = currM;
	}

	public void setShield(float currS)
	{
		shield.value = currS;
	}
}
