using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Audio;

public class Hunting : MonoBehaviour {

	public EventList eventList;
	public GameObject imageEffect;
	[Space(5)]
	public GameObject storyChooser;
	public Text storyDesc;
	[Space(5)]
	public GameObject story;
	public Text storyText;
	public RectTransform optionHolder;
	[Space(5)]
	public GameObject result;
	public Text resultStory;
	public Text resultText;
	[Space(5)]
	public AudioMixerSnapshot normalMix;
	public AudioMixerSnapshot huntMix;

	private Event currentEvent = null;

	public void Show() {
		if(currentEvent != null)
			return;
		currentEvent = eventList.getRandomEvent();

		storyDesc.text = currentEvent.description;
		storyChooser.SetActive(true);

		storyText.text = currentEvent.story;
		SetOptions(currentEvent.options);
		huntMix.TransitionTo(1.5f);
		imageEffect.SetActive(true);
	}

	public void SetOptions(EventOption[] opts) {
		int i = 0;
		foreach (RectTransform child in optionHolder) {
			if(i < opts.Length) {
				child.gameObject.SetActive(true);
				child.GetChild(0).GetComponent<Text>().text = opts[i].title;
				child.GetComponent<Button>().onClick.RemoveAllListeners();
				EventOption temp = opts[i];
				child.GetComponent<Button>().onClick.AddListener(() => { SelectOption(temp); });
			} else {
				child.gameObject.SetActive(false);
			}
			i++;
		}
	}

	public void SelectOption (EventOption opt) {
		if (opt.options != null && opt.options.Length != 0) {
			storyText.text = opt.story;
			SetOptions(opt.options);
			Debug.Log ("new options");
		}
		else {
			story.SetActive(false);

			resultStory.text = opt.story;
			resultText.text = (opt.result.power == 0? "":"Strength:\t\t\t"+opt.result.power.ToString("+#;-#;")+"\n")
				+(opt.result.money == 0? "":"Gold:\t\t\t\t"+opt.result.money.ToString("+#;-#;")+"\n")
					+(opt.result.population == 0? "":"Population:\t\t"+opt.result.population.ToString("+#;-#;")+"\n")
					+(opt.result.reputation == 0? "":"Reputation:\t\t"+opt.result.reputation.ToString("+#;-#;")+"\n")
					+(opt.result.guards == 0? "":"Guards:\t\t\t"+opt.result.guards.ToString("+#;-#;"));
			if(opt.result.power > 0)
				Data.power.delta = 0;
			Data.power.amount += opt.result.power;
			Data.money.amount += opt.result.money;
			Data.population.amount += opt.result.population;
			Data.reputation.amount += opt.result.reputation;
			Data.guards += opt.result.guards;
			UserInterface.DrawStats();

			result.SetActive(true);
		}
	}

	public void Close() {
		storyChooser.SetActive(false);
		story.SetActive(false);
		result.SetActive(false);
		currentEvent = null;
		normalMix.TransitionTo(.7f);
		imageEffect.SetActive(false);
	}

	public void Cancel() {
		storyChooser.SetActive(false);
		story.SetActive(false);
		Data.power.amount--;
		UserInterface.DrawStats();
		currentEvent = null;
		normalMix.TransitionTo(.7f);
		imageEffect.SetActive(false);
	}
}
