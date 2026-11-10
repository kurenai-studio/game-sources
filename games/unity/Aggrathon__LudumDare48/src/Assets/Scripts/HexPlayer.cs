using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.Tilemaps;

[RequireComponent(typeof(Inventory))]
[RequireComponent(typeof(PlayerAudio))]
public class HexPlayer : MonoBehaviour
{
    public GridWorld world;
    public MoveButton moveUpButton;
    public MoveButton moveLeftButton;
    public MoveButton moveRightButton;
    public MoveButton moveStayButton;
    public InteractionUI interactionUI;

    public float speed = 3.0f;

    Vector3Int tilemapPos;
    Inventory inventory;
    PlayerAudio playerAudio;

    public enum State
    {
        Ready,
        Moving,
        Waiting,
    }

    State state;
    Vector3 target;
    CustomTile.TileInfo queuedInteraction;
    bool canStay;

    public State CurrentState { get { return state; } }
    public PlayerAudio CurrentAudio { get { return playerAudio; } }
    public Inventory CurrentInventory { get { return inventory; } }


    void Start()
    {
        inventory = GetComponent<Inventory>();
        playerAudio = GetComponent<PlayerAudio>();
        SnapToTile();
        state = State.Waiting;
        queuedInteraction = new CustomTile.TileInfo();
        canStay = true;
    }

    private void Update()
    {
        if (state == State.Moving)
        {
            var move = target - transform.position;
            float dist = speed * Time.deltaTime;
            if (move.sqrMagnitude < dist * dist)
            {
                transform.position = target;
                if (queuedInteraction.interaction != CustomTile.Interaction.None)
                {
                    InteractWithTile(queuedInteraction);
                    queuedInteraction.interaction = CustomTile.Interaction.None;
                }
                else
                {
                    state = State.Waiting;
                    GiveControl();
                }
            }
            else
            {
                transform.position += move.normalized * dist;
            }
        }
    }

    [ContextMenu("Snap to tile")]
    void SnapToTile()
    {
        tilemapPos = world.GetTile(transform.position);
        transform.position = world.SnapToTile(tilemapPos);
    }

    void TryEnterTile(Vector3Int pos)
    {
        if (state != State.Ready)
            return;
        var ti = world.GetTileInfo(pos);
        if (tilemapPos != pos)
        {
            if (inventory.CanEnterTile(ti))
            {
                canStay = true;
                tilemapPos = pos;
                target = world.SnapToTile(tilemapPos);
                state = State.Moving;
                HideMoveButtons();
                playerAudio.PlaySteps();
                inventory.energy.value -= ti.energy;
                inventory.food.value -= ti.food;
                queuedInteraction = Random.value < ti.encounterChance ? ti : queuedInteraction;
                inventory.UpdateUI();
            }
            else
            {
                playerAudio.PlayError();
                GiveControl();
            }
        }
        else
        {
            if (canStay)
            {
                canStay = false;
                inventory.time--;
                inventory.food.value -= ti.food;
                inventory.energy.Refill();
                InteractWithTile(ti);
                inventory.UpdateUI();
            }
            else
            {
                playerAudio.PlayError();
                GiveControl();
            }
        }
    }

    void InteractWithTile(CustomTile.TileInfo ti)
    {
        HideMoveButtons();
        state = State.Waiting;
        interactionUI.StartEncounter(this, ti);
    }

    public void GiveControl()
    {
        if (state == State.Waiting)
            state = State.Ready;
        if (inventory.CheckDead())
        {
            state = State.Waiting;
            HideMoveButtons();
        }
        else
        {
            inventory.UpdateUI();
            ShowMoveButtons();
        }
    }

    void ShowMoveButtons()
    {
        var ti = world.GetTileInfo(world.TopOf(tilemapPos));
        bool canEnterUp = inventory.CanEnterTile(ti);
        moveUpButton.Enable(ti, false, canEnterUp, GoUp);
        ti = world.GetTileInfo(world.LeftOf(tilemapPos));
        bool canEnterLeft = inventory.CanEnterTile(ti);
        moveLeftButton.Enable(ti, false, canEnterLeft, GoLeft);
        ti = world.GetTileInfo(world.RightOf(tilemapPos));
        bool canEnterRight = inventory.CanEnterTile(ti);
        moveRightButton.Enable(ti, false, canEnterRight, GoRight);
        canStay = canStay || !(canEnterLeft | canEnterRight | canEnterUp);
        moveStayButton.Enable(world.GetTileInfo(tilemapPos), true, canStay, Stay);
    }

    void HideMoveButtons()
    {
        moveUpButton.Disable();
        moveLeftButton.Disable();
        moveRightButton.Disable();
        moveStayButton.Disable();
    }


    public void OnUp(InputAction.CallbackContext input)
    {
        if (input.performed)
            GoUp();
    }

    public void GoUp()
    {
        TryEnterTile(world.TopOf(tilemapPos));
    }

    public void OnDown(InputAction.CallbackContext input)
    {
        if (input.performed)
        {
            Stay();
        }
    }

    public void Stay()
    {
        TryEnterTile(tilemapPos);
    }

    public void OnLeft(InputAction.CallbackContext input)
    {
        if (input.performed)
            GoLeft();
    }
    public void GoLeft()
    {
        TryEnterTile(world.LeftOf(transform.position));
    }

    public void OnRight(InputAction.CallbackContext input)
    {
        if (input.performed)
            GoRight();
    }

    public void GoRight()
    {
        TryEnterTile(world.RightOf(transform.position));
    }
}
