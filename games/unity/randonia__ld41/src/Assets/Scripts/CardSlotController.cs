using UnityEngine;

public class CardSlotController : MonoBehaviour
{
    private GameObject mCurrentCard;

    public bool isOccupied { get { return mCurrentCard != null; } }

    // Use this for initialization
    private void Start()
    {
        BoxCollider collider = GetComponent<BoxCollider>();
        RectTransform rT = GetComponent<RectTransform>();
        collider.size = new Vector3(rT.rect.width, rT.rect.height, 20);
    }

    // Update is called once per frame
    private void Update()
    {
        if (mCurrentCard != null)
        {
            Debug.DrawLine(transform.position, mCurrentCard.transform.position, Color.yellow);
        }
    }

    // Put the card back. This overrides the testing in the PlaceCard!
    public void ReturnCard(GameObject card)
    {
        if (mCurrentCard != null && mCurrentCard != card)
        {
            Debug.LogWarning(string.Format("Attempting to return a card [{0}] that is not the current card [{1}]!", card.name, mCurrentCard.name));
            return;
        }
        mCurrentCard = card;
        iTween.MoveTo(card, iTween.Hash("position", transform.position, "time", Random.Range(0.1f, 0.35f)));
    }

    public void PlaceCard(GameObject card)
    {
        Debug.Log(gameObject.name + " receiving card " + card.name);
        mCurrentCard = card;
    }

    public GameObject TakeCard()
    {
        GameObject result = mCurrentCard;
        if (mCurrentCard != null)
        {
            Debug.Log(gameObject.name + " removing card " + mCurrentCard.name);
            mCurrentCard = null;
        }
        return result;
    }

    private void OnDrawGizmos()
    {
        TextGizmo.Instance.DrawText(transform.position + Vector3.down * 40f, string.Format("occupied: {0}", isOccupied));
    }
}