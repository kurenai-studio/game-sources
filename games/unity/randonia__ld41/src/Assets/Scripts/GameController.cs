using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public enum GameState
{
    Starting,
    Initializing,
    Playing,
    Paused,
    Victory,
    Menu
}

public enum AudioCategory
{
    CardPlace,
    CardPlay,
    CardShuffle
}

public class GameController : MonoBehaviour
{
    public GameState mState = GameState.Playing;

    public Sprite mMuteSprite;
    public Sprite mPlayingSprite;
    private DeckController mDeck;
    private HandController mHand;
    private DiscardPileController mDiscardPile;
    private PlayerController mPlayer;
    private GameObject mPlayZone;
    private GameObject mCamera;
    private float mStartTime;
    private float mPlayTime;
    public float Playtime { get { return mPlayTime; } }
    public GameObject PREFAB_CARD;

    public GameObject AudioPlayerBGM;
    public GameObject AudioPlayerCardPlace;
    public GameObject AudioPlayerCardPlay;
    public GameObject AudioPlayerShuffle;

    private float mLastCardAdd;
    public float kCardAddToHandDelay = 0.125f;

    // Use this for initialization
    private void Start()
    {
        mDeck = GameObject.Find("Deck").GetComponent<DeckController>();
        mHand = GameObject.Find("Action Hand").GetComponent<HandController>();
        mDiscardPile = GameObject.Find("Discard Pile").GetComponent<DiscardPileController>();
        mPlayer = GameObject.Find("Player").GetComponent<PlayerController>();
        mCamera = GameObject.Find("Main Camera");
        mPlayZone = GameObject.Find("Play Zone");

        Debug.Assert(mDeck != null);
        Debug.Assert(mPlayZone != null);
        Debug.Assert(mHand != null);
        Debug.Assert(mDiscardPile != null);
        Debug.Assert(mPlayer != null);
        Debug.Assert(mCamera != null);

        Debug.Assert(PREFAB_CARD != null, "You must assign the Card Prefab in the inspector");
        mStartTime = Time.time;
        mPlayTime = 0;
    }

    // Update is called once per frame
    private void Update()
    {
        if (mState != GameState.Victory)
        {
            mPlayTime += Time.deltaTime;
        }
        switch (mState)
        {
            case GameState.Starting:
                // Initialize the game
                InitializeGameplay();
                Invoke("RecursivelyAddCardsToHand", 2.5f);
                mState = GameState.Initializing;
                break;
            case GameState.Initializing:
                break;
            case GameState.Playing:
                if (mHand.HasRoom && !mDeck.IsEmpty && (mLastCardAdd + kCardAddToHandDelay < Time.time))
                {
                    AddCardToHand();
                    mLastCardAdd = Time.time;
                }
                break;
        }
    }

    public void WinGame()
    {
        mState = GameState.Victory;
    }

    private void StartGameCallback()
    {
        mState = GameState.Playing;
        Debug.Log("Starting game!");
    }

    /// <summary>
    /// Stupid function to recursively invoke itself until no cards exist
    /// </summary>
    private void RecursivelyAddCardsToHand()
    {
        if (mHand.HasRoom)
        {
            Invoke("RecursivelyAddCardsToHand", 0.25f);
            AddCardToHand();
        }
        else
        {
            Debug.Log("Finished recursively adding cards to hand");
            Invoke("StartGameCallback", 1.0f);
        }
    }

    private void InitializeGameplay()
    {
        // Create cards for your starter deck
        Queue<GameObject> newDeck2 = new Queue<GameObject>();

        // Make 5 each Run-1
        int numRunLevel1 = 5;
        for (int c = 1; c <= numRunLevel1; ++c)
        {
            newDeck2.Enqueue(MakeCard(CardType.RunLeft, 1));
        }
        for (int c = 1; c <= numRunLevel1; ++c)
        {
            newDeck2.Enqueue(MakeCard(CardType.RunRight, 1));
        }

        // Make 2 each Run-2
        int numRunLevel2 = 5;
        for (int c = 1; c <= numRunLevel2; ++c)
        {
            newDeck2.Enqueue(MakeCard(CardType.RunLeft, 2));
        }
        for (int c = 1; c <= numRunLevel2; ++c)
        {
            newDeck2.Enqueue(MakeCard(CardType.RunRight, 2));
        }

        // Make 1 each Run-3
        int numRunLevel3 = 1;
        for (int c = 1; c <= numRunLevel3; ++c)
        {
            newDeck2.Enqueue(MakeCard(CardType.RunLeft, 3));
        }
        for (int c = 1; c <= numRunLevel3; ++c)
        {
            newDeck2.Enqueue(MakeCard(CardType.RunRight, 3));
        }

        // Make 5 Jump-Low
        int numJumpLow = 5;
        for (int c = 1; c <= numJumpLow; ++c)
        {
            newDeck2.Enqueue(MakeCard(CardType.JumpLow, 1));
        }
        // Make 2 Jump-High
        int numJumpHigh = 5;
        for (int c = 1; c <= numJumpHigh; ++c)
        {
            newDeck2.Enqueue(MakeCard(CardType.JumpHigh, 1));
        }

        while (newDeck2.Count > 0)
        {
            mDeck.AddCardToDeck(newDeck2.Dequeue());
        }
        mDeck.ShuffleDeck();
    }

    private GameObject MakeCard(CardType type, int power = -1)
    {
        // Random for now
        GameObject result = Instantiate(PREFAB_CARD);
        PlayingCardController card = result.GetComponent<PlayingCardController>();
        card.cardType = type;
        card.cardPower = power;
        card.LoadAsset();
        Debug.Log("New card created: " + card.cardType + ", " + card.cardPower);
        result.name = string.Format("card_{0}_{1}", card.cardType, card.cardPower);
        return result;
    }

    public void OnMuteToggle()
    {
        AudioSource bgm = AudioPlayerBGM.GetComponent<AudioSource>();
        if (bgm.isPlaying)
        {
            bgm.Pause();
        }
        else
        {
            bgm.UnPause();
        }
        GameObject muteSprite = GameObject.Find("MuteButton");
        muteSprite.GetComponent<Image>().sprite = (bgm.isPlaying) ? mPlayingSprite : mMuteSprite;
    }

    public void PlayAudio(AudioCategory audio)
    {
        GameObject target = null;
        switch (audio)
        {
            case AudioCategory.CardPlace:
                target = AudioPlayerCardPlace;
                break;
            case AudioCategory.CardPlay:
                target = AudioPlayerCardPlay;
                break;
            case AudioCategory.CardShuffle:
                target = AudioPlayerShuffle;
                break;
        }
        if (target != null)
        {
            // Get all the audio sources
            AudioSource[] sources = target.GetComponents<AudioSource>();
            // Pick a random one
            int randomSource = Random.Range(0, sources.Length);
            sources[randomSource].Play();
        }
    }

    public void AddCardToHand()
    {
        if (mHand.HasRoom)
        {
            GameObject newCard = mDeck.GetCard();
            if (newCard != null)
            {
                mHand.TakeCardIntoHand(newCard);
                PlayAudio(AudioCategory.CardPlace);
            }
        }
    }

    public void ActivateCard(PlayingCardController card)
    {
        mPlayer.ActOnCard(card);
        mDiscardPile.AddToDiscard(card.gameObject);
        PlayAudio(AudioCategory.CardPlay);
        DiscardHand();
    }

    public void CheckDeck()
    {
        if (mHand.HasRoom && mDeck.IsEmpty)
        {
            Debug.Log("Deck does not have enough cards, reshuffle discard pile");
            ReshuffleDiscard();
        }
        else
        {
            Debug.Log("Deck has enough cards");
        }
    }

    public void ReshuffleDiscard()
    {
        if (!mDeck.IsEmpty)
        {
            Debug.LogWarning("Called Reshuffle but the deck isn't empty");
            return;
        }
        Debug.Log("Shuffling Discard into deck!");
        List<GameObject> newDeck = new List<GameObject>();
        while (!mDiscardPile.IsEmpty)
        {
            newDeck.Add(mDiscardPile.RemoveFromDiscard());
        }
        if (newDeck.Count > 0)
        {
            PlayAudio(AudioCategory.CardShuffle);
        }
        // Randomly place each card back into the deck
        newDeck.Sort((left, right) => 1 - Random.Range(0, 3));
        foreach (GameObject go in newDeck)
        {
            mDeck.AddCardToDeck(go, true);
        }
        mDeck.SortDeckZIndex();
    }

    public void ActivateCardPair(GameObject firstCard, GameObject secondCard)
    {
        PlayingCardController card1 = firstCard.GetComponent<PlayingCardController>();
        PlayingCardController card2 = secondCard.GetComponent<PlayingCardController>();
        Debug.Log("Combining cards: " + firstCard.name + " + " + secondCard.name);
        PlayAudio(AudioCategory.CardPlay);
        mPlayer.ActOnCardPair(card1, card2);
        ConsumeCard(card1);
        ConsumeCard(card2, false);
        DiscardHand();
    }

    public void DiscardHand()
    {
        // Put discards into discard pile
        List<PlayingCardController> discards = mHand.DiscardRemainingHand();
        foreach (PlayingCardController pcc in discards)
        {
            pcc.OnDiscarded();
            mDiscardPile.AddToDiscard(pcc.gameObject);
        }
        Invoke("CheckDeck", 0.5f);
    }

    public void ScrapCard(GameObject cardToScrap)
    {
        Debug.Log("Scrapping card! " + cardToScrap.name);
        Destroy(cardToScrap);
        DiscardHand();
    }

    public void ConsumeCard(PlayingCardController card, bool isFirst = true)
    {
        Vector3 targetDir = ((isFirst) ? Vector3.right : Vector3.left) * 50.0f;
        Vector3 targetPosition = mPlayZone.transform.position + targetDir;
        // Move to the "consume combo!" position, then callback onCardComsumed
        iTween.MoveTo(card.gameObject, iTween.Hash("position", targetPosition, "time", 0.45f, "oncomplete", "onCardConsumed", "oncompletetarget", gameObject, "oncompleteparams", card));
    }

    public void onCardConsumed(PlayingCardController card)
    {
        mDiscardPile.AddToDiscard(card.gameObject);
    }
}