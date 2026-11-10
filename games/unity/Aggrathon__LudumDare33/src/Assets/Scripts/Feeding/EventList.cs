using UnityEngine;

public class EventList : ScriptableObject {
	public Event[] events;

	public Event getRandomEvent() {
		return events[Random.Range(0, events.Length)];
	}
}


[System.Serializable]
public class Event {
	public string description;
	[TextArea()]
	public string story;
	public EventOption[] options;
}
[System.Serializable]
public class EventOption{
	public string title;
	[TextArea()]
	public string story;

	public EventOption[] options;
	public EventReward result;
}
[System.Serializable]
public class EventReward {
	public int money = 0;
	public int reputation = -15;
	public int population = -1;
	public int power = 10;
	public int guards = 0;
}
