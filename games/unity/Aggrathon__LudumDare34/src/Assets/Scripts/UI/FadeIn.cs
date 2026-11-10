using UnityEngine;
using UnityEngine.UI;

public class FadeIn : MonoBehaviour
{
	private Image img;
	public float speed = 2f;
	
	void Start()
	{
		img = GetComponent<Image>();
	}
	
	void Update()
	{
		img.color = Color.Lerp(img.color,Color.black, Time.deltaTime * speed);
	}
}
