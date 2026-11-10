using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// Power cards have:
/// Direction + Power
/// </summary>
public enum CardType
{
    RunLeft,
    RunRight,
    JumpLow,
    JumpHigh,
    Block
}

public class PlayingCardController : MonoBehaviour
{
    public bool Clickable;
    public Sprite[] mReplacementSprites;
    public CardType cardType;
    public int cardPower;

    private PlayerController mPlayer;
    private GameController mGameController;

    #region Drag Properties

    private Vector3 mDragOffset;

    // If this is getting picked up, keep tabs on the starter slot in to clear it out
    private Transform mSourceTarget;

    private Transform mDropTarget;
    private Vector3 kDropOffset = new Vector3(0, 0, -1.0f);

    #endregion Drag Properties

    // Use this for initialization
    private void Start()
    {
        mPlayer = GameObject.Find("Player").GetComponent<PlayerController>();
        mGameController = GameObject.Find("GameController").GetComponent<GameController>();
    }

    public void LoadAsset()
    {
        Image img = GetComponent<Image>();
        switch (cardType)
        {
            case CardType.JumpLow:
                img.sprite = mReplacementSprites[0];
                break;
            case CardType.JumpHigh:
                img.sprite = mReplacementSprites[1];
                break;
            case CardType.RunLeft:
                switch (cardPower)
                {
                    case 1:
                        img.sprite = mReplacementSprites[3];

                        break;
                    case 2:
                        img.sprite = mReplacementSprites[4];

                        break;
                    case 3:
                        img.sprite = mReplacementSprites[5];

                        break;
                }
                break;
            case CardType.RunRight:
                switch (cardPower)
                {
                    case 1:
                        img.sprite = mReplacementSprites[6];
                        break;
                    case 2:
                        img.sprite = mReplacementSprites[7];
                        break;
                    case 3:
                        img.sprite = mReplacementSprites[8];
                        break;
                }
                break;
        }
    }

    // Update is called once per frame
    private void Update()
    {
        if (mSourceTarget != null)
        {
            Debug.DrawLine(transform.position, mSourceTarget.transform.position, Color.gray);
        }
        if (mDropTarget != null)
        {
            Debug.DrawLine(transform.position, mDropTarget.transform.position, Color.green);
        }
    }

    public void OnTriggerEnter(Collider other)
    {
        //Debug.Log(string.Format("{0} >>> Entering >>> {1}", gameObject.name, other.name));
        mDropTarget = other.transform;
    }

    public void OnTriggerExit(Collider other)
    {
        //Debug.Log(string.Format("{0} <<< Exiting <<< {1}", gameObject.name, other.name));
        if (mDropTarget == other.transform)
        {
            mDropTarget = null;
        }
    }

    public void OnBeginDrag()
    {
        if (!Clickable)
        {
            return;
        }
        if (mDropTarget != null)
        {
            mSourceTarget = mDropTarget;
        }
        mDragOffset = Input.mousePosition - transform.position;
        transform.SetAsLastSibling();
    }

    public void OnDrag()
    {
        if (!Clickable)
        {
            return;
        }
        transform.position = Input.mousePosition - mDragOffset;
    }

    public void OnDiscarded()
    {
        mSourceTarget = null;
    }

    public void OnEndDrag()
    {
        if (!Clickable)
        {
            return;
        }
        if (mDropTarget && mDropTarget != mSourceTarget)
        {
            Debug.Log("Droptarget exists: " + mDropTarget.name);
            // See if the target is occupied
            CardSlotController csc = mDropTarget.GetComponent<CardSlotController>();
            if (csc != null)
            {
                // If it's occupied combine the two
                if (csc.isOccupied)
                {
                    Debug.Log("Droptarget is occupied! " + mDropTarget.name);
                    // Go back to the source
                    if (mSourceTarget == null)
                    {
                        Debug.LogWarning("Something bad happened the source target should not be null");
                    }
                    CardSlotController sourceCSC = mSourceTarget.GetComponent<CardSlotController>();
                    mSourceTarget = null;
                    GameObject otherCard = csc.TakeCard();
                    otherCard.GetComponent<PlayingCardController>().mSourceTarget = null;
                    mGameController.ActivateCardPair(sourceCSC.TakeCard(), otherCard);
                    return;
                }
            }
            GoToDropTarget();
        }
        else
        {
            ReturnToSource();
        }
    }

    private void ReturnToSource()
    {
        // Go back to the source
        if (mSourceTarget != null)
        {
            CardSlotController cscOrig = mSourceTarget.GetComponent<CardSlotController>();
            cscOrig.ReturnCard(gameObject);
            mDropTarget = mSourceTarget;
        }
        else
        {
            Debug.LogWarning("Source target for " + name + " is undefined but you tried to return!");
        }
    }

    private void GoToDropTarget()
    {
        // Do not drop if we don't have anything to drop
        if (mDropTarget == null)
        {
            Debug.Log("Returning card to origin - droptarget is null");
            ReturnToSource();
            return;
        }
        if (mDropTarget == mSourceTarget)
        {
            Debug.Log("Target is source, returning");
            ReturnToSource();
            return;
        }
        // Clear the old CSC if it is one
        if (mSourceTarget != null)
        {
            CardSlotController oldCSC = mSourceTarget.GetComponent<CardSlotController>();
            if (oldCSC)
            {
                Debug.Log("Clearing old CSC:" + mSourceTarget.name);
                oldCSC.TakeCard();
            }
        }
        switch (mDropTarget.tag)
        {
            case "PlayZone":
                Debug.Log("Playing card: " + gameObject.name);
                mGameController.ActivateCard(this);
                mSourceTarget = null;
                mDropTarget = null;
                break;
            case "ScrapZone":
                mGameController.ScrapCard(gameObject);
                mSourceTarget = null;
                mDropTarget = null;
                break;
            default:
                ReturnToSource();
                break;
        }
        //transform.position = mDropTarget.transform.position + kDropOffset;
    }

    private void OnDrawGizmos()
    {
        TextGizmo.Instance.DrawText(transform.position, string.Format("{0},{1}", cardType, cardPower));
        TextGizmo.Instance.DrawText(transform.position + Vector3.down * 10f, string.Format("touchable: {0}", Clickable));
        if (mSourceTarget)
        {
            Debug.DrawLine(transform.position, mSourceTarget.transform.position, Color.cyan);
            TextGizmo.Instance.DrawText(transform.position + Vector3.down * 15f, string.Format("sourceTarget: {0}", mSourceTarget.name));
        }
    }
}