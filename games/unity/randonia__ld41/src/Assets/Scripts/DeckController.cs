using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DeckController : MonoBehaviour
{
    public GameObject CardSortingLayer;

    public Vector3 Center
    {
        get
        {
            RectTransform rT = GetComponent<RectTransform>();
            return transform.position + new Vector3(rT.rect.width * 0.5f, rT.rect.height * 0.5f, 0);
        }
    }

    private Stack<GameObject> mDeck;

    public bool IsEmpty { get { return mDeck.Count == 0; } }

    // Use this for initialization
    private void Start()
    {
        mDeck = new Stack<GameObject>();
        CardSortingLayer = GameObject.Find("CardContainer");
    }

    // Update is called once per frame
    private void Update()
    {
    }

    public void AddCardToDeck(GameObject card, bool tween = false)
    {
        Debug.Log("Adding card " + card.name + " to deck");
        card.transform.SetParent(CardSortingLayer.transform);
        Vector3 targetPos = Center + Vector3.forward + Vector3.down * 5.0f * mDeck.Count;
        if (tween)
        {
            iTween.MoveTo(card, iTween.Hash("position", targetPos, "time", Random.Range(0.1f, 0.35f)));
        }
        else
        {
            card.transform.position = targetPos;
        }
        mDeck.Push(card);
        card.GetComponent<PlayingCardController>().Clickable = false;
    }

    public void ShuffleDeck()
    {
        List<GameObject> shufflePile = new List<GameObject>();
        while (mDeck.Count > 0)
        {
            shufflePile.Add(mDeck.Pop());
        }
        shufflePile.Sort((left, right) => 1 - Random.Range(0, 3));
        foreach (GameObject go in shufflePile)
        {
            AddCardToDeck(go, true);
        }
        SortDeckZIndex();
    }

    public void SortDeckZIndex()
    {
        // In order, set each of the cards to the right sorting order
        foreach (GameObject go in mDeck)
        {
            go.transform.SetAsFirstSibling();
        }
    }

    public GameObject GetCard()
    {
        if (mDeck.Count < 1)
        {
            return null;
        }
        GameObject card = mDeck.Pop();
        card.GetComponent<PlayingCardController>().Clickable = true;
        return card;
    }
}