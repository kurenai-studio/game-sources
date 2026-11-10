using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

public class SelectionMarker2 : MonoBehaviour
{

	Vector3 start;
	bool selecting;

	void Update()
	{
		if (Input.GetMouseButtonDown(0) && !EventSystem.current.IsPointerOverGameObject())
		{
			RaycastHit hit;
			if (Physics.Raycast(Camera.main.ScreenPointToRay(Input.mousePosition), out hit))
			{
				start = hit.point;
				transform.GetChild(0).gameObject.SetActive(true);
				selecting = true;
			}
		}
		if (Input.GetMouseButton(0))
		{
			if (selecting)
			{
				Vector3 end = start;
				RaycastHit hit;
				if (Physics.Raycast(Camera.main.ScreenPointToRay(Input.mousePosition), out hit))
				{
					end = hit.point;
				}
				transform.position = new Vector3(Mathf.Max(start.x, end.x), 0f, Mathf.Min(start.z, end.z));
				(transform as RectTransform).sizeDelta = new Vector2(Mathf.Abs(start.x - end.x), Mathf.Abs(start.z - end.z));
			}
		}
		else if (Input.GetMouseButtonUp(0))
		{
			transform.GetChild(0).gameObject.SetActive(false);
			selecting = false;
		}
	}
}
