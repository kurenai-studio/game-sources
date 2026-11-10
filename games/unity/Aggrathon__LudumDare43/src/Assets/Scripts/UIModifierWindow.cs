using UnityEngine;
using System.Collections;
using TMPro;
using UnityEngine.UI;

public class UIModifierWindow : MonoBehaviour
{
	public State player;
	public UIPiety pietyDisplay;
	public TextMeshProUGUI title;
	public GameObject cancelButton;

	AStateModifier curse;

	public void ShowBlessings()
	{
		title.text = "Blessings";
		for (int i = transform.childCount; i < player.blessings.Count + 2; i++)
			Instantiate(transform.GetChild(2), transform);
		for (int i = 0; i < player.blessings.Count; i++)
		{
			Transform panel = transform.GetChild(i + 2);
			panel.GetChild(0).GetComponent<TextMeshProUGUI>().text = player.blessings[i].name;
			panel.GetChild(1).GetComponent<TextMeshProUGUI>().text = player.blessings[i].description;
			Button button = panel.GetComponent<Button>();
			button.onClick.RemoveAllListeners();
			int j = i;
			button.onClick.AddListener(() => {
				player.Bless(player.blessings[j]);
				gameObject.SetActive(false);
				pietyDisplay.UpdateNextTick();
			});
			button.interactable = player.piety > player.blessings[i].cost;
			panel.gameObject.SetActive(true);
		}
		for (int i = player.blessings.Count + 2; i < transform.childCount; i++)
			transform.GetChild(i).gameObject.SetActive(false);
		gameObject.SetActive(true);
	}

	public void ShowCurses()
	{
		title.text = "Curses";
		for (int i = transform.childCount; i < player.curses.Count + 2; i++)
			Instantiate(transform.GetChild(2), transform);
		for (int i = 0; i < player.curses.Count; i++)
		{
			Transform panel = transform.GetChild(i + 2);
			panel.GetChild(0).GetComponent<TextMeshProUGUI>().text = player.curses[i].name;
			panel.GetChild(1).GetComponent<TextMeshProUGUI>().text = player.curses[i].description;
			Button button = panel.GetComponent<Button>();
			button.onClick.RemoveAllListeners();
			int j = i;
			button.onClick.AddListener(() => {
				curse = player.curses[j];
				gameObject.SetActive(false);
				cancelButton.SetActive(true);
				UIStateSelectors.SelectState(OnSelect);
			});
			button.interactable = player.piety > player.curses[i].cost;
			panel.gameObject.SetActive(true);
		}
		for (int i = player.curses.Count + 2; i < transform.childCount; i++)
			transform.GetChild(i).gameObject.SetActive(false);
		gameObject.SetActive(true);
	}

	void OnSelect(State state)
	{
		cancelButton.SetActive(false);
		player.Curse(curse, state);
		pietyDisplay.UpdateNextTick();
	}
}
