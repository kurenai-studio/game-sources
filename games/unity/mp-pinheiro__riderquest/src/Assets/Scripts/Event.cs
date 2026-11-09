using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class Event : MonoBehaviour {
    public UnityEvent callback;
    static HashSet<string> usedEvents;
    public bool autoStart;

    // Use this for initialization
    void Start() {
        //create set once
        if (usedEvents == null) {
            usedEvents = new HashSet<string>();
        }

        //auto-start event
        if (autoStart) StartEvent();
    }

    void OnCollisionEnter2D(Collision2D other) {
        //on hero touch event
        StartEvent();
    }

    void OnTriggerEnter2D(Collider2D other) {
        //on hero touch event
        StartEvent();
    }

    void StartEvent() {
        //call method
        string name = callback.GetPersistentMethodName(0);
        if (name == "TealPrizes" || !usedEvents.Contains(name)) {
            usedEvents.Add(name);
            callback.Invoke();
        }
    }

    public void Dream() {
        StartCoroutine(DreamRoutine());
    }
    IEnumerator DreamRoutine() {
        yield return MessageManager.ShowMessage("Voice", Global.playerName + "... " + Global.playerName + "... It's coming... You must... You have to...");
        Player.Teleport("bedroom", 0.29f, 0.31f);
    }

    public void WakeUp() {
        StartCoroutine(WakeUpRoutine());
    }
    IEnumerator WakeUpRoutine() {
        yield return MessageManager.ShowMessage(Global.motherName, Global.playerName + " wake up! Breakfast is ready!");
        yield return MessageManager.ShowMessage(Global.playerName, "What a strange dream...");
    }

    public void Breakfast() {
        StartCoroutine(BreakfastRoutine());
    }
    IEnumerator BreakfastRoutine() {
        yield return MessageManager.ShowMessage(Global.fatherName, "Look who's finally up! Ready for our little adventure today, pal?");
        yield return MessageManager.ShowMessage(Global.playerName, "We are really going!?");
        yield return MessageManager.ShowMessage(Global.fatherName, "Yes! I told you we would.");
        yield return MessageManager.ShowMessage(Global.motherName, "I still think you're too young to go hunting.");
        yield return MessageManager.ShowMessage(Global.fatherName, "We are going to be just fine! I'll bring him back in one piece, don't worry.");
        yield return MessageManager.ShowMessage(Global.motherName, "Alright, alright. Have fun, you two.");
        Player.Teleport("overworld", -0.11f, 0.58f);
    }

    public void Hunt() {
        StartCoroutine(HuntRoutine());
    }
    IEnumerator HuntRoutine() {
        yield return MessageManager.ShowMessage(Global.playerName, "Wow! I've never been so far away from the village.");
        yield return MessageManager.ShowMessage(Global.fatherName, "This is the real world, son! Far north is " + Global.village2Name + ", the village I was born in. And to the east is " + Global.kingdomName + ", the capital of the kingdom, where I met your mother.");
        yield return MessageManager.ShowMessage(Global.fatherName, "All around us there's wonders and adventure.");
        yield return MessageManager.ShowMessage(Global.playerName, "I want to travel the world one day, like father did.");
        yield return MessageManager.ShowMessage(Global.fatherName, "I am sure you will. Now let's hunt some food! Let's go west, to the " + Global.forestName + ", there's game to give and lose there.");
    }

    public void FindDeer() {
        StartCoroutine(FindDeerRoutine());
    }
    IEnumerator FindDeerRoutine() {
        yield return MessageManager.ShowMessage(Global.fatherName, "Alright, son, here we go. Hunting is a simple, but meticulous process.");
        yield return MessageManager.ShowMessage(Global.fatherName, "Some people think hunting means lurking in the shadows, staying silent and waiting for a moment to strike.");
        yield return MessageManager.ShowMessage(Global.fatherName, "Those people die of starvation.");
        yield return MessageManager.ShowMessage(Global.fatherName, "If you want to catch something, you have to think like your prey, you have to put yourself on its tires.");
        yield return MessageManager.ShowMessage(Global.fatherName, "So, if you see a deer, charge at it at full speed. ");
    }

    public void FoundDeer() {
        StartCoroutine(FoundDeerRoutine());
    }
    IEnumerator FoundDeerRoutine() {
        yield return MessageManager.ShowMessage(Global.fatherName, "There it is! Quick, catch it!");
    }

    public void HouseAssault() {
        StartCoroutine(HouseAssaultRoutine());
    }
    IEnumerator HouseAssaultRoutine() {
        CameraFollow.setMusic(Resources.Load<AudioClip>("Music/crisis"));
        yield return MessageManager.ShowMessage(Global.fatherName, "Hey!");
        yield return MessageManager.ShowMessage(Global.fatherName, "Son, go to " + Global.ancientName + "'s house.");
        yield return MessageManager.ShowMessage(Global.playerName, "Dad, what's happening? Where is mom?");
        yield return MessageManager.ShowMessage(Global.fatherName, "I said go!");
        yield return MessageManager.ShowMessage(Global.fatherName, "We will talk later.");
        yield return MessageManager.ShowMessage(Global.blackName, "You. Do you have it?");
        yield return MessageManager.ShowMessage(Global.fatherName, "Get out of my home!");
        yield return MessageManager.ShowMessage(Global.fatherName, "Where is my wife?");
        yield return MessageManager.ShowMessage(Global.blackName, "Everything will be okay if you tell us where it is.");
        yield return MessageManager.ShowMessage(Global.fatherName, "I don't know what you're talking about!");
        GetComponentInChildren<Enemy>().StartBattle();
    }

    public void HouseAssault2() {
        StartCoroutine(HouseAssault2Routine());
    }
    IEnumerator HouseAssault2Routine() {
        yield return MessageManager.ShowMessage(Global.blackName, "We don't have to do this. Just tell us where it is.");
        Global.ancientAppears = true;
        Transform ancient = transform.GetChild(1).GetChild(0);
        yield return ancient.GetComponent<Manipulator>().MoveTo(new Vector2(1.05f, -19.44f), 1.0f);
        yield return MessageManager.ShowMessage(Global.ancientName, "Come on, " + Global.playerName + ", we have to go.");
        yield return MessageManager.ShowMessage(Global.playerName, Global.ancientName + ", you have to help my father! They have my mom!");
        yield return MessageManager.ShowMessage(Global.ancientName, "Let's go, I said!");
        yield return MessageManager.ShowMessage(Global.playerName, "No...!");
        Global.anotherBlack = true;
        yield return MessageManager.ShowMessage(Global.blackName, "It's not here.");
        yield return MessageManager.ShowMessage(Global.blackName, "Get rid of them.");
        yield return MessageManager.ShowMessage(Global.playerName, "NO! DAD!");
        yield return MessageManager.ShowMessage(Global.ancientName, "I am sorry, my child, I have to keep you safe.");
        ancient.GetComponent<AudioSource>().Play();
        ScreenHider.HideScreen();
        yield return new WaitForSeconds(1f);
        GetComponentInChildren<AudioSource>().Play();
        yield return new WaitForSeconds(3f);
        Player.Teleport("dream", 0f, 0f);
    }

    public void Dream2() {
        StartCoroutine(Dream2Routine());
    }
    IEnumerator Dream2Routine() {
        yield return MessageManager.ShowMessage("Voice", "They still don't have it... I couldn't give it to them.");
        yield return MessageManager.ShowMessage("Voice", "Son. You have to keep it safe. They must not have it.");
        yield return MessageManager.ShowMessage("Voice", "You must protect it. Find " + Global.friendName + "...");
        Player.Teleport("ancientHouse", 0.98f, -0.33f);
    }

    public void AncientTalks() {
        StartCoroutine(AncientTalksRoutine());
    }
    IEnumerator AncientTalksRoutine() {
        yield return MessageManager.ShowMessage(Global.playerName, "D-dad...");
        yield return MessageManager.ShowMessage(Global.ancientName, "You are up, my child, I was worried.");
        yield return MessageManager.ShowMessage(Global.playerName, "Mom and dad, what... what happened?");
        yield return MessageManager.ShowMessage(Global.ancientName, "It's time, son. It's time for you to learn the truth.");
        yield return MessageManager.ShowMessage(Global.playerName, "I... I don't understand...");
        yield return MessageManager.ShowMessage(Global.ancientName, "Those men that attacked your home, they are not common bandits.");
        yield return MessageManager.ShowMessage(Global.ancientName, "Those are the Black Tires. An elite force that works directly under the King's authority.");
        yield return MessageManager.ShowMessage(Global.ancientName, "Long ago, way before you came into this world. Before your father met your mother and settled in this village he was one of them.");
        yield return MessageManager.ShowMessage(Global.playerName, "But my father hated the kingdom...");
        yield return MessageManager.ShowMessage(Global.ancientName, "It wasn't always like this. ");
        yield return MessageManager.ShowMessage(Global.ancientName, "I worked in the kingdom as a blacksmith, forging engines for the King. Your father and I were close friends.");
        yield return MessageManager.ShowMessage(Global.ancientName, "We used to meet every week. He'd come to collect the engines and see to my payment.");
        yield return MessageManager.ShowMessage(Global.ancientName, "One day, however, he didn't come. I thought it to be strange, as he never once missed a day, or was late.");
        yield return MessageManager.ShowMessage(Global.ancientName, "But I didn't think much of it.");
        yield return MessageManager.ShowMessage(Global.ancientName, "The next week he didn't show again. Nor the next. Instead, a different man came on the third week to collect the engines. ");
        yield return MessageManager.ShowMessage(Global.ancientName, "He paid me for everything, and when I asked where your father went, or why they didn't come on the passing weeks, he told me schedule was tight, and he didn't");
        yield return MessageManager.ShowMessage(Global.ancientName, "know who your father was.");
        yield return MessageManager.ShowMessage(Global.ancientName, "On the following day, I received a misterious letter telling me to go to the town square in the middle of night. It was your father's hand writting.");
        yield return MessageManager.ShowMessage(Global.playerName, "I... that is all so strange...");
        yield return MessageManager.ShowMessage(Global.ancientName, "When I got there, your father was waiting for me. He had a worried look in his eyes, and held a strange package. He was with a man I hadn't seen before.");
        yield return MessageManager.ShowMessage(Global.ancientName, "There, he introduced to his friend " + Global.friendName + ", and they told me the world was in great danger.");
        yield return MessageManager.ShowMessage(Global.ancientName, "They told me in that package was an amulet of great power. That the king used dark and untold arts to create this amuled. That he seeked to become a god.");
        yield return MessageManager.ShowMessage(Global.ancientName, "I didn't understand at the time, but I trusted your father.");
        yield return MessageManager.ShowMessage(Global.ancientName, "He asked me to change his car color, so he wouldn't be recognized. So I did.");
        yield return MessageManager.ShowMessage(Global.ancientName, "On the following night, we met your mother on the east gate of the city, and she led us through a secret passage outside.");
        yield return MessageManager.ShowMessage(Global.ancientName, "Once we got out, your father gave the amulet to " + Global.friendName + ". He was told to hide it, and come back to the kingdom. As for me, your father and your mother, we ran away");
        yield return MessageManager.ShowMessage(Global.ancientName, "to this village.");
        yield return MessageManager.ShowMessage(Global.playerName, "It's all about the amulet, then... My dreams... they...");
        yield return MessageManager.ShowMessage(Global.ancientName, "If the Black Tires find the amulet, the world will be in great danger. ");
        yield return MessageManager.ShowMessage(Global.playerName, "I must find it. My father, he was talking to me in my dreams.");
        yield return MessageManager.ShowMessage(Global.ancientName, "I cannot tell you not to go, child. But if you must, know that it will be dangerous.");
        yield return MessageManager.ShowMessage(Global.ancientName, "I knew this moment would come one day, but as time passed, and I got older, for a couple of sweet moments, I thought it wouldn't.");
        yield return MessageManager.ShowMessage(Global.ancientName, "In the basement you can find everything I gathered in preparation for this day. But now I am old, and weak, it is of no use to me.");
        yield return MessageManager.ShowMessage(Global.ancientName, "Take it, child. Find " + Global.friendName + " and protect the amulet!");
        yield return MessageManager.ShowMessage(Global.playerName, "I will! My father's death will not be in vain!");
        Global.talkedToAncient = true;
        Player.Teleport("overworld", -10.32f, -20.72f);
    }

    public void GreenEncounter() {
        StartCoroutine(GreenEncounterRoutine());
    }
    IEnumerator GreenEncounterRoutine() {
        yield return MessageManager.ShowMessage("Red Car 1", "You're cornered, you filthy thief!");
        yield return MessageManager.ShowMessage(Global.greenName, "Hey, come on, this is a misuderstading!");
        yield return MessageManager.ShowMessage("Red Car 2", "Shut up, thief! You'll pay for what you stole with your life!");
        yield return MessageManager.ShowMessage(Global.playerName, "Hey! Leave him alone!");
        yield return MessageManager.ShowMessage("Red Car 1", "Stay out of this, kid!");
        GetComponentInChildren<Enemy>().StartBattle();
    }

    public void GreenEncounter2() {
        StartCoroutine(GreenEncounter2Routine());
    }
    IEnumerator GreenEncounter2Routine() {
        yield return MessageManager.ShowMessage(Global.playerName, "Damn, that bridge is busted. ");
        yield return MessageManager.ShowMessage(Global.greenName, "Yeah, that almost got me killed. Woosh! You need to cross too?");
        yield return MessageManager.ShowMessage(Global.playerName, "I need to get to " + Global.kingdomName + ".");
        yield return MessageManager.ShowMessage(Global.greenName, "Dude, sweet! I do too! I know a way around the river, but it's a little bit dangerous. Not okay to go there alone, but the two of us can handle it. Probably. We make a");
        yield return MessageManager.ShowMessage(Global.greenName, "heck of a team!");
        yield return MessageManager.ShowMessage(Global.playerName, "I don't usually team up with thiefs...");
        yield return MessageManager.ShowMessage(Global.greenName, "Dude, I only steal from jerks. And old people.  Kidding. Haha, I'm funny.");
        yield return MessageManager.ShowMessage(Global.playerName, "You are one strange man.");
        yield return MessageManager.ShowMessage(Global.greenName, "Name's " + Global.greenName + ". Nice to meet you.");
        yield return MessageManager.ShowMessage(Global.playerName, "I'm " + Global.playerName + ". Nice to meet you too. You are as strange as your name.");
        yield return MessageManager.ShowMessage(Global.greenName, "Don't worry about it. So, let's get going. It's easy, just follow the river side, always north, we'll find a way through there.");
        yield return MessageManager.ShowMessage(Global.playerName, "Alright.");
        Global.greenJoins = true;
    }

    public void WitchEntrance() {
        StartCoroutine(WitchEntranceRoutine());
    }
    IEnumerator WitchEntranceRoutine() {
        yield return MessageManager.ShowMessage(Global.playerName, "Wait... I've heard about this place...!");
        yield return MessageManager.ShowMessage(Global.playerName, "Your \"alternative path\" is through the " + Global.dungeon1Name + "!?");
        yield return MessageManager.ShowMessage(Global.greenName, "Dude. Chill. It's cool.");
        yield return MessageManager.ShowMessage(Global.playerName, "You know a witch lives here, right?");
        yield return MessageManager.ShowMessage(Global.greenName, "Nah, those are legends, man. I've been here a thousand times, it's alright, kinda gloomy, though.");
        yield return MessageManager.ShowMessage(Global.playerName, "I thought you said it wasn't okay to come here alone.");
        yield return MessageManager.ShowMessage(Global.greenName, "Don't worry about it. Let's go.");
        yield return MessageManager.ShowMessage("Fairfruit", "Disclaimer: this is the final part of the 'game' and it's highly unfinished.");
        Player.Teleport("dungeon1", 32.51f, -5.89f);
    }

    public void WitchEncounter() {
        StartCoroutine(WitchEncounterRoutine());
    }
    IEnumerator WitchEncounterRoutine() {
        yield return MessageManager.ShowMessage(Global.greenName, "Yo, there it is! I told you it was cool.");
        yield return MessageManager.ShowMessage(Global.playerName, "Yeah, let's get out of here. This place gives me chills.");
        yield return MessageManager.ShowMessage(Global.greenName, "For sure, let's ditch.");
    }

    public void WitchLeave()
    {
        StartCoroutine(WitchLeaveRoutine());
    }
    IEnumerator WitchLeaveRoutine()
    {
        yield return MessageManager.ShowMessage(Global.playerName, "Stop joking around, let's go.");
        yield return MessageManager.ShowMessage(Global.greenName, "For sure, for sure, just gimme a second.");
        yield return MessageManager.ShowMessage(Global.playerName, "What is up with you?");
        yield return MessageManager.ShowMessage(Global.greenName, "Erm. I kind of, maybe, can't move.");
        yield return MessageManager.ShowMessage(Global.playerName, "Are you kidding me?");
        yield return MessageManager.ShowMessage(Global.playerName, "Wait, are those spider web in your tires!?");
        yield return MessageManager.ShowMessage("???", "Kyahahahahahahahahaha!");
        Global.witchAppears = true;
    }

    public void WitchAppears()
    {
        StartCoroutine(WitchAppearsRoutine());
    }
    IEnumerator WitchAppearsRoutine()
    {
        yield return MessageManager.ShowMessage("Teal", "You got some sweet rides over there, kids.");
        yield return MessageManager.ShowMessage("Teal", "Can't wait to add them to my car collection!");
        yield return MessageManager.ShowMessage("Teal", "And you to my stomach, of course.");

        yield return MessageManager.ShowMessage(Global.greenName, "Dude, a little help here.");
        yield return MessageManager.ShowMessage(Global.playerName, "Let us pass!");

        yield return MessageManager.ShowMessage("Teal", "Kyahahahah!");
        GetComponentInChildren<Enemy>().StartBattle();
    }

    public void TealPrizes(GameObject go)
    {
        StartCoroutine(TealPrizeRoutine(go));
    }
    IEnumerator TealPrizeRoutine(GameObject go)
    {
        var option = Random.Range(1, 4);
        switch(option)
        {
            case 1:
                yield return MessageManager.ShowMessage("God", "Teal gives chat 1000 coins.");
                break;
            case 2:
                yield return MessageManager.ShowMessage("God", "Fairfruit gifts 2 subs.");
                break;
            case 3:
                yield return MessageManager.ShowMessage("God", "Teal gives chat 2500 coins.");
                break;
        }

        go.SetActive(false);
    }
}