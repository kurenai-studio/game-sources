using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class GameState : MonoBehaviour
{
    [Header("Times")]
    [SerializeField] float eventInterval = 10f;
    float eventTimer = 0f;
    [SerializeField] float dayLength = 60f;
    float dayTime = 0f;
    int dayIndex = 0;
    readonly string[] dayNames = { "Night", "Morning", "Day", "Evening" };

    [Header("Power")]
    [SerializeField] AnimationCurve powerDemand;
    float powerOffset = 0f;
    bool powerWarn;
    public float GasPrice { get; protected set; }
    public float CarbonTax { get; protected set; }
    float maxPower = 1f;

    // [Header("Power plants")]
    // [SerializeField] List<APowerPlant> powerPlantPrefabs;
    List<APowerPlant> powerPlants;

    [Header("Events")]
    [SerializeField] List<GameEvent> events;
    HashSet<GameEvent> randomEvents;
    int eventIndex = -1;
    float totRandom;

    [Header("Mood")]
    [SerializeField] float moodMax = 50;
    float mood;
    int moodDelta;
    readonly string[] moodNames = { "<<<", "<<", "<", "", ">" };

    [Header("Sounds")]
    [SerializeField] AudioClip eventSound;

    [Header("Integrations")]
    [SerializeField] Messages messages;
    [SerializeField] BuildingUI buildUI;
    [SerializeField] AudioManager audioManager;

    [Header("UI")]
    [SerializeField] Image eventClock;
    [SerializeField] TextMeshProUGUI eventDescription;
    [SerializeField] Image dayClock;
    [SerializeField] TextMeshProUGUI dayDescription;
    [SerializeField] Image powerInput;
    [SerializeField] Image powerOutput;
    [SerializeField] GameObject powerWarning;
    [SerializeField] Image priceMeter;
    [SerializeField] Image moodMeter;
    [SerializeField] TextMeshProUGUI moodTrend;

    public GameEvent CurrentEvent { get; protected set; }

    public static GameState Instance { get; protected set; }

    public float DayFrac { get { return dayTime / dayLength; } }

    private void Awake()
    {
        Instance = this;
        powerPlants = new List<APowerPlant>();
        randomEvents = new HashSet<GameEvent>();
        totRandom = 0f;
    }

    private void OnDestroy()
    {
        if (Instance == this)
            Instance = null;
    }

    public void AddPowerPlant(APowerPlant plant)
    {
        powerPlants.Add(plant);
    }


    void Start()
    {
        maxPower = 1f;
        mood = moodMax;
        eventTimer = eventInterval - 1f;
        dayTime = 0f;
        dayIndex = -1;
        eventIndex = -1;
        eventDescription.text = "";
        powerOffset = 0f;
        GasPrice = 0f;
        CarbonTax = 0f;
        CalculateStats();
        foreach (var ev in events)
        {
            if (ev.probability > 0f && !randomEvents.Contains(ev))
            {
                randomEvents.Add(ev);
                totRandom += ev.probability;
            }
        }
    }

    void Update()
    {
        dayTime += Time.deltaTime;
        if (dayTime > dayLength)
        {
            dayTime -= dayLength;
        }
        eventTimer += Time.deltaTime;
        if (eventTimer > eventInterval)
        {
            eventTimer -= eventInterval;
            NextEvent();
        }
        mood += (float)moodDelta * Time.deltaTime;
        CalculateStats();
    }

    void CalculateStats()
    {
        float cost = 0.0f;
        float powerIn = 0.0f;
        foreach (var p in powerPlants)
        {
            cost += p.GetCost();
            powerIn += p.GetPower();
        }
        priceMeter.fillAmount = cost;
        float powerOut = powerDemand.Evaluate(dayTime / dayLength) + powerOffset;
        powerOut = Mathf.Clamp01(powerOut) * maxPower;
        if (CurrentEvent != null)
            powerOut += CurrentEvent.powerDemand;
        powerOutput.fillAmount = powerOut / maxPower;
        powerInput.fillAmount = powerIn / maxPower;
        powerWarn = powerIn < powerOut - 0.01f;
        if (powerWarn != powerWarning.activeSelf)
            powerWarning.SetActive(powerWarn);
        int moodChange = 0;
        if (powerWarn)
            moodChange -= 2;
        if (cost < 0.25f)
            moodChange++;
        else if (cost > 0.6f)
            moodChange--;
        if (moodChange != moodDelta)
        {
            moodDelta = moodChange;
            moodTrend.text = moodNames[moodChange + 3];
        }
        if (mood <= 0)
        {
            messages.ShowDefeat();
        }
        else if (mood > moodMax)
        {
            mood = moodMax;
        }
        moodMeter.fillAmount = mood / moodMax;
        float dayFrac = dayTime / dayLength;
        dayClock.fillAmount = dayFrac;
        int dayId = Mathf.FloorToInt(dayFrac * (float)dayNames.Length);
        if (dayId != dayIndex)
        {
            dayDescription.text = dayNames[dayId];
            dayIndex = dayId;
        }
        eventClock.fillAmount = eventTimer / eventInterval;
    }

    void NextEvent()
    {
        eventIndex++;
        if (eventIndex < events.Count)
        {
            CurrentEvent = events[eventIndex];
        }
        else
        {
            if (randomEvents.Count == 0)
                eventDescription.text = string.Format("Event {0}", eventIndex);
            else
            {
                float rnd = Random.value * totRandom;
                foreach (var item in randomEvents)
                {
                    if (rnd <= item.probability)
                    {
                        CurrentEvent = item;
                        break;
                    }
                    rnd -= item.probability;
                }
            }
        }
        if (CurrentEvent != null)
        {
            eventDescription.text = CurrentEvent.description;
            CarbonTax += CurrentEvent.carbonTax;
            GasPrice = Mathf.Max(0f, GasPrice + CurrentEvent.gasPrice);
            maxPower += CurrentEvent.powerIncrese;
            switch (CurrentEvent.action)
            {
                case GameEvent.Action.Tutorial:
                    messages.ShowNextTutorial();
                    break;
                case GameEvent.Action.Victory:
                    messages.ShowVictory();
                    break;
                case GameEvent.Action.Build:
                    buildUI.gameObject.SetActive(true);
                    break;
            }
            audioManager.PlayOneShot(eventSound, false);
        }
    }
}
