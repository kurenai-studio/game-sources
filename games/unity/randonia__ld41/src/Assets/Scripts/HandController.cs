using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HandController : MonoBehaviour
{
    private List<CardSlotController> mSlots;

    public bool HasRoom
    {
        get
        {
            foreach (CardSlotController csc in mSlots)
            {
                if (!csc.isOccupied)
                {
                    return true;
                }
            }
            return false;
        }
    }

    // Use this for initialization
    private void Start()
    {
        mSlots = new List<CardSlotController>();
        for (int childIdx = 0; childIdx < transform.childCount; ++childIdx)
        {
            Transform child = transform.GetChild(childIdx);
            if (child.gameObject.activeInHierarchy && child.CompareTag("Card Slot"))
            {
                CardSlotController childCSC = child.GetComponent<CardSlotController>();
                if (childCSC == null)
                {
                    Debug.LogError("Child in index " + childIdx + " has no CardSlotController");
                }
                else
                {
                    mSlots.Add(childCSC);
                }
            }
        }
    }

    // Update is called once per frame
    private void Update()
    {
    }

    public List<PlayingCardController> DiscardRemainingHand()
    {
        List<PlayingCardController> result = new List<PlayingCardController>();
        foreach (CardSlotController csc in mSlots)
        {
            if (csc.isOccupied)
            {
                result.Add(csc.TakeCard().GetComponent<PlayingCardController>());
            }
        }
        return result;
    }

    public bool TakeCardIntoHand(GameObject card)
    {
        // Find the first open one and tween it
        foreach (CardSlotController csc in mSlots)
        {
            if (!csc.isOccupied)
            {
                csc.PlaceCard(card);
                iTween.MoveTo(card, iTween.Hash("position", csc.transform.position, "time", 0.25f));
                return true;
            }
        }
        return false;
    }
}