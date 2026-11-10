using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using System.Collections;

public class SelectionMarker : MonoBehaviour {

	Vector2 start;
	Image img;
	
	void Start () {
		img = GetComponent<Image>();
	}
	
	void Update () {
		if(Input.GetMouseButtonDown(0) && !EventSystem.current.IsPointerOverGameObject())
		{
			start = Input.mousePosition;
			img.enabled = true;
		}
		if (Input.GetMouseButton(0))
		{
			if(img.enabled)
			{
				Vector2 end = Input.mousePosition;
				img.rectTransform.anchoredPosition = new Vector2(Mathf.Min(start.x, end.x), Mathf.Min(start.y, end.y));
				img.rectTransform.sizeDelta = new Vector2(Mathf.Abs(start.x - end.x), Mathf.Abs(start.y - end.y));
			}
		}
		else if (Input.GetMouseButtonUp(0))
		{
			img.enabled = false;
		}
	}
}
