using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MouseController : MonoBehaviour
{
    public float minimumSummonDistance = 1.0f;
    private bool isReadyToSummon = false;
    public Texture2D cursorTexture;
    public Vector2 cursorHotspot;
    public CursorMode cursorMode = CursorMode.Auto;

    public GameObject summoningCirclePrefab;
    public GameObject summoningTargetPrefab;

    public bool isHeld = false;

    private Vector2 targetWorldPosition;
    private Vector2 spawnWorldPosition;
    private GameObject summoningCircle;
    private GameObject cursor;
    private Animator cursorAnimator;
    private PlayerController playerController;

    // Start is called before the first frame update
    void Start()
    {
        cursor = Instantiate(summoningTargetPrefab, Vector2.zero, Quaternion.identity);
        playerController = GetComponentInParent<PlayerController>();
        cursorAnimator = cursor.GetComponent<Animator>();
        Cursor.visible = false;
    }

    void OnMouseEnter()
    {
        Cursor.SetCursor(cursorTexture, cursorHotspot, cursorMode);
    }

    void OnMouseExit()
    {
        //Cursor.SetCursor(null, Vector2.zero, cursorMode);
    }

    // Update is called once per frame
    void LateUpdate()
    {
        targetWorldPosition = Camera.main.ScreenToWorldPoint(Input.mousePosition);
        cursor.transform.position = targetWorldPosition;
        isReadyToSummon =
            Vector2.Distance(spawnWorldPosition, targetWorldPosition) > minimumSummonDistance;

        if (Input.GetMouseButtonDown(0) && playerController.isAlive)
        {
            isHeld = true;
            spawnWorldPosition = Camera.main.ScreenToWorldPoint(Input.mousePosition);
            summoningCircle = Instantiate(
                summoningCirclePrefab,
                spawnWorldPosition,
                Quaternion.identity
            );
        }
        else if (Input.GetMouseButtonUp(0))
        {
            isHeld = false;
            if (isReadyToSummon)
            {
                Quaternion spawnDirection = Quaternion.Euler(
                    0,
                    0,
                    Mathf.Atan2(
                        targetWorldPosition.y - spawnWorldPosition.y,
                        targetWorldPosition.x - spawnWorldPosition.x
                    ) * Mathf.Rad2Deg
                        - 90
                );
                GetComponentInParent<PlayerController>()
                    .Summon(spawnWorldPosition, targetWorldPosition);
                summoningCircle.GetComponent<SummoningController>().Despawn(true, spawnDirection);
            }
            else
            {
                summoningCircle.GetComponent<SummoningController>().Despawn(false, null);
            }
        }

        if (isHeld)
        {
            if (isReadyToSummon)
            {
                cursorAnimator.SetBool("active", true);
            }
            else
            {
                cursorAnimator.SetBool("active", false);
            }
        }
        else
        {
            cursorAnimator.SetBool("active", false);
        }
    }
}
