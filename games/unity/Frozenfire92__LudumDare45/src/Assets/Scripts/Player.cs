using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Rigidbody2D))]
public class Player : MonoBehaviour
{
    public float speed;
    public ISelectable selection;
    public SelectionMarker selectionMarker;
    public bool tutorialMode = false;
    public bool tutorialMove = false;
    public GameObject building;
    public float worldPaddingMin = 1f;
    public float worldPaddingMax = 9f;

    private Rigidbody2D rb2d;
    private List<ISelectable> selectionPool;
    private GameObject currentPlot;
    private BoxCollider2D playerCollider;
    private CircleCollider2D selectionTrigger;
    private BoxCollider2D playerTrigger;

    #region Lifecycle
    void Start()
    {
        rb2d = GetComponent<Rigidbody2D>();
        selectionPool = new List<ISelectable>();

        var colliders = GetComponents<BoxCollider2D>();
        playerCollider = colliders[0];
        playerTrigger = colliders[1];
        selectionTrigger = GetComponent<CircleCollider2D>();
    }

    private void Update()
    {
        if (Input.GetMouseButtonDown(0)) { SelectNext(); }
        if (Input.GetMouseButtonDown(1)) { ClearSelection(); }

        if (!tutorialMode && Input.GetKeyDown(KeyCode.Space))
        {
            if (currentPlot != null && currentPlot.GetComponent<Plot>().resourceCount <= 0 && GameController.instance.resources >= GameController.instance.buildingCost)
            {
                //if (GameController.instance.resources >= GameController.instance.buildingCost)
                //{
                GameController.instance.resources -= GameController.instance.buildingCost;
                UIController.instance.UpdateResources();
                Instantiate(building, currentPlot.transform.position, Quaternion.identity);
                Destroy(currentPlot);
                currentPlot = null;
                GameController.instance.botsAvailable++;
                //}
            }
            else
            {
                if (selection != null)
                {
                    MonoBehaviour mb = selection as MonoBehaviour;
                    if (mb != null)
                    {
                        GameController.instance.SendBot(mb.gameObject);
                    }
                }
            }
        }
    }

    void FixedUpdate()
    {
        if (!tutorialMode || (tutorialMode && tutorialMove))
        {
            float h = Input.GetAxis("Horizontal");
            float v = Input.GetAxis("Vertical");

            rb2d.AddForce(new Vector2(h, v) * speed);

            if (!tutorialMode)
            {
                if (rb2d.position.x < worldPaddingMin)
                {
                    rb2d.position = new Vector2(worldPaddingMin, rb2d.position.y);
                    rb2d.velocity = Vector2.zero;
                }

                if (rb2d.position.x > worldPaddingMax)
                {
                    rb2d.position = new Vector2(worldPaddingMax, rb2d.position.y);
                    rb2d.velocity = Vector2.zero;
                }

                if (rb2d.position.y < worldPaddingMin)
                {
                    rb2d.position = new Vector2(rb2d.position.x, worldPaddingMin);
                    rb2d.velocity = Vector2.zero;
                }

                if (rb2d.position.y > worldPaddingMax)
                {
                    rb2d.position = new Vector2(rb2d.position.x, worldPaddingMax);
                    rb2d.velocity = Vector2.zero;
                }
            }
        }
    }
    #endregion

    #region Triggers
    private void OnTriggerEnter2D(Collider2D collision)
    {
        if (collision.IsTouching(selectionTrigger))
        {
            ISelectable selectable = collision.gameObject.GetComponent<ISelectable>();
            if (selectable != null)
            {
                selectionPool.Add(selectable);

                // Autoselection, do we want this?
                //if (selectionPool.Count == 1){ selection = selectable; selectionMarker.Target(collision.gameObject); }
            }

            if (tutorialMode && collision.gameObject.CompareTag("TutorialGoal"))
            {
                TutorialController.instance.ShowFinalMessage();
            }

        }

        if (collision.IsTouching(playerTrigger))
        {
            if (collision.gameObject.CompareTag("Plot"))
            {
                if (GameController.instance.resources >= GameController.instance.buildingCost)
                {
                    currentPlot = collision.gameObject;
                    Plot p = collision.gameObject.GetComponent<Plot>();
                    p.ShowMessage();
                }
            }
        }
    }

    private void OnTriggerExit2D(Collider2D collision)
    {
        ISelectable selectable = collision.gameObject.GetComponent<ISelectable>();
        if (selectable != null)
        {
            selectionPool.Remove(selectable);
            if (selection == selectable) { ClearSelection(); }
        }

        if (collision.gameObject.CompareTag("Plot"))
        {
            if (collision.gameObject == currentPlot)
            {
                currentPlot = null;
            }
            Plot p = collision.gameObject.GetComponent<Plot>();
            p.HideMessage();
        }
    }
    #endregion

    #region Selection
    private void ClearSelection()
    {
        selection = null;
        selectionMarker.Target(null);
    }

    private void SelectNext()
    {
        if (selectionPool.Count == 0) { ClearSelection(); }
        else
        {
            int existingIndex = selectionPool.IndexOf(selection);
            int index = existingIndex > -1
                ? existingIndex >= selectionPool.Count - 1
                    ? 0
                    : existingIndex + 1
                : 0;

            MonoBehaviour mb = selectionPool[index] as MonoBehaviour;
            if (mb != null)
            {
                selection = selectionPool[index];
                selectionMarker.Target(mb.gameObject);
            }
        }
    }
    #endregion
}