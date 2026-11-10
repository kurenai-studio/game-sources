using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class BlockSpawner : MonoBehaviour
{
    [SerializeField] List<SirtetBlock> blocks;
    SirtetBlock current;
    int index;

    public bool multiple = false;
    public bool rotate = false;
    public float minDist = 8f;
    public float speedUpgrade = 0f;

    float speedBoost;

    public LineRenderer lr;
    public float ropeSpeed = 15f;
    Vector3[] lrPositions;

    void Start()
    {
        index = blocks.Count;
        current = null;
        speedBoost = 0f;
        if (lr)
        {
            lrPositions = new Vector3[5];
            lrPositions[0] = transform.position + Vector3.forward * 0.1f;
            lrPositions[1] = transform.position + Vector3.forward * 0.1f;
            lrPositions[2] = transform.position + Vector3.forward * 0.1f + Vector3.up;
            lrPositions[3] = transform.position + Vector3.forward * 0.1f;
            lrPositions[4] = transform.position + Vector3.forward * 0.1f;
            lr.SetPositions(lrPositions);
        }
    }


    void Update()
    {
        if (!current || ((multiple || !current.enabled) && Vector3.SqrMagnitude(transform.position - current.transform.position) > minDist * minDist))
        {
            if (index >= blocks.Count)
            {
                blocks.Shuffle();
                index = 0;
            }
            speedBoost += speedUpgrade;
            if (rotate)
            {
                Quaternion rot = Quaternion.Euler(0f, 0f, Random.Range(0, 4) * 90f);
                current = Instantiate(blocks[index], transform.position, rot);
            }
            else
            {
                current = Instantiate(blocks[index], transform.position, transform.rotation);
            }
            index++;
            current.speed += speedBoost;
            if (multiple)
            {
                current.releaseSound = null;
                current.dropSound = null;
            }
            if (lr)
            {
                lrPositions[0] = current.transform.position;
                lrPositions[1].x = lrPositions[0].x;
                lr.SetPositions(lrPositions);
            }
        }
        else if (lr)
        {
            lrPositions[0] = current.transform.position;
            lrPositions[1].x = lrPositions[0].x;
            lrPositions[3].x = Mathf.MoveTowards(lrPositions[3].x, lrPositions[1].x, ropeSpeed * 0.5f * Time.deltaTime);
            lrPositions[4] = Vector3.MoveTowards(lrPositions[4], current.transform.position, ropeSpeed * Time.deltaTime);
            lr.SetPositions(lrPositions);
        }
    }


    public void Down(InputAction.CallbackContext context)
    {
        if (current)
        {
            current.Down(!context.canceled);
        }
    }

    public void Right(InputAction.CallbackContext context)
    {
        if (context.started && current)
        {
            current.Right();
        }
    }

    public void Left(InputAction.CallbackContext context)
    {
        if (context.started && current)
        {
            current.Left();
        }
    }

    public void RotateLeft(InputAction.CallbackContext context)
    {
        if (context.started && current)
        {
            current.RotateLeft();
        }
    }

    public void RotateRight(InputAction.CallbackContext context)
    {
        if (context.started && current)
        {
            current.RotateRight();
        }
    }

    public void Drop(InputAction.CallbackContext context)
    {
        if (context.started && current)
        {
            current.Drop();
        }
    }
}
