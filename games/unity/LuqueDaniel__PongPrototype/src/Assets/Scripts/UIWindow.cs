using UnityEngine;
using UnityEngine.EventSystems;

public class UIWindow : MonoBehaviour
{
	public GameObject openFocusButton;
	public GameObject closeFocusButton;

	void OnEnable()
	{
		Time.timeScale = 0;
		EventSystem.current.SetSelectedGameObject(openFocusButton);
	}

	void OnDisable()
	{
		Time.timeScale = 1;
		EventSystem.current.SetSelectedGameObject(closeFocusButton);
	}
}
