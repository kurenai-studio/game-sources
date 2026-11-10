using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DiscardPileController : MonoBehaviour
{
    public Vector3 Center
    {
        get
        {
            RectTransform rT = GetComponent<RectTransform>();
            return transform.position + new Vector3(rT.rect.width * 0.5f, rT.rect.height * 0.5f, 0);
        }
    }

    public bool IsEmpty { get { return mDiscardPile.Count == 0; } }
    private Stack<GameObject> mDiscardPile;

    // Use this for initialization
    private void Start()
    {
        mDiscardPile = new Stack<GameObject>();
    }

    // Update is called once per frame
    private void Update()
    {
    }

    public void AddToDiscard(GameObject card)
    {
        // Tween it over!
        mDiscardPile.Push(card);
        Vector3 targetPosition = Center + Vector3.down * 2.0f * mDiscardPile.Count;
        card.GetComponent<PlayingCardController>().Clickable = false;
        iTween.MoveTo(card, iTween.Hash("position", targetPosition, "time", 0.25f));
        SortZIndex();
    }

    public void SortZIndex()
    {
        foreach (GameObject go in mDiscardPile)
        {
            go.transform.SetAsFirstSibling();
        }
    }

    public GameObject RemoveFromDiscard()
    {
        return mDiscardPile.Pop();
    }
}