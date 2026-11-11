using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(Rigidbody))]
public class PlayerController : MonoBehaviour
{
    public InputActionAsset actions;
    public Camera playerCamera;
    public Transform arm;
    public TextMeshProUGUI dialogText;
    public TextMeshProUGUI tooltipText;
    public TextMeshProUGUI heightTip;
    public Animator animationController;
    public Phone phone;
    public GameState gameState;
    public float mouseSpeed = 1;
    public Vector2 lookLimits = new Vector2(-60, 60);
    public float walkSpeed = 2;
    public float runSpeed = 6;
    public float jumpHeight = 2;
    public float jumpAngle = 45;
    public float maxInteractDistance = 1.5f;
    public float dialogRecordTtl = 3;
    public float dialogRecordWriteTime = 0.5f;
    public AnimationCurve textTransparencyCurve;
    public AudioClip[] phoneSounds;
    public AudioClip walk;
    public AudioClip jump;
    public AudioSource walkSource;
    public AudioSource jumpSource;

    InputAction lookAction;
    InputAction moveAction;
    InputAction jumpAction;
    InputAction sprintAction;
    InputAction attackAction;
    InputAction interactAction;
    float verticalLookAngle = 0;
    Rigidbody rigidBody;
    bool canJump;
    float JumpVelocity => Mathf.Sqrt(2 * Physics.gravity.magnitude * jumpHeight);
    Transform ThingInArm = null;
    class DialogRecord
    {
        public float spawnTime;
        public string writer;
        public string text;
    }
    LinkedList<DialogRecord> dialogRecords = new();
    InputActionMap playerInputMap;

    void Start()
    {
        Cursor.lockState = CursorLockMode.Locked;

        rigidBody = GetComponent<Rigidbody>();
        playerInputMap = actions.FindActionMap("Player");
        playerInputMap.Enable();
        lookAction = playerInputMap.FindAction("Look");
        moveAction = playerInputMap.FindAction("Move");
        jumpAction = playerInputMap.FindAction("Jump");
        sprintAction = playerInputMap.FindAction("Sprint");
        attackAction = playerInputMap.FindAction("Attack");
        interactAction = playerInputMap.FindAction("Interact");

        walkSource.clip = walk;
        jumpSource.clip = jump;
    }

    void Update()
    {
        heightTip.text = $"{(transform.position.y - 0.3f).ToString("F1")}m";

        Vector2 lookValue = lookAction.ReadValue<Vector2>();
        lookValue = lookValue * mouseSpeed;
        verticalLookAngle = Mathf.Clamp(verticalLookAngle + lookValue.y, lookLimits.x, lookLimits.y);
        playerCamera.transform.localRotation = Quaternion.AngleAxis(verticalLookAngle, Vector3.left);
        transform.rotation = Quaternion.AngleAxis(lookValue.x, Vector3.up) * transform.rotation;

        bool shownPhone = animationController.GetBool("ShowPhone");
        bool phoneButton = attackAction.WasPressedThisFrame();
        bool armButton = interactAction.WasPressedThisFrame();

        tooltipText.text = "";
        Interactinator interactinator = null;
        if (Physics.Raycast(playerCamera.transform.position, playerCamera.transform.forward, out var hitInfo, maxInteractDistance))
        {
            interactinator = hitInfo.collider.GetComponentInParent<Interactinator>();
            if (interactinator != null && ThingInArm == null)
            {
                tooltipText.text = $"[E] {interactinator.tooltip}";
            }
        }

        if (armButton)
        {
            if (ThingInArm != null)
                Put();
            else if (shownPhone)
                animationController.SetBool("ShowPhone", false);
            else
            {
                if (interactinator != null)
                {
                    interactinator.Interact(this);
                }
            }
        }
        else if (phoneButton)
        {
            if (ThingInArm != null)
                Put();
            else
                animationController.SetBool("ShowPhone", !shownPhone);
        }

        while (dialogRecords.Count > 10 ||
                dialogRecords.Count > 0 &&
                dialogRecords.First.Value.spawnTime > 0 &&
                Time.time - dialogRecords.First.Value.spawnTime > dialogRecordTtl * dialogRecords.First.Value.text.Length
            )
            dialogRecords.RemoveFirst();

        string dialogString = "";
        bool prevRecordWritten = true;
        foreach (var record in dialogRecords)
        {
            if (prevRecordWritten && record.spawnTime < 0)
                record.spawnTime = Time.time;
            if (record.spawnTime < 0)
                break;
            float deltaTime = Time.time - record.spawnTime;
            string text = record.text;
            bool recordWritten = deltaTime > text.Length * dialogRecordWriteTime;
            if (!recordWritten)
            {
                int sliceIndex = (int)(deltaTime / dialogRecordWriteTime);
                text = $"{text.Substring(0, sliceIndex)}<alpha=#00>{text.Substring(sliceIndex)}";
            }

            float transparencyValue = textTransparencyCurve.Evaluate(deltaTime / (dialogRecordTtl * record.text.Length));
            string hexValue = ((int)(transparencyValue * 255)).ToString("X2");
            dialogString +=
                record.writer == null ?
                $"<color=#E0D7B9><alpha=#{hexValue}>{text}\n" :
                $"<color=#D9D9D9><alpha=#{hexValue}>{record.writer}: <color=#E0D7B9><alpha=#{hexValue}>{text}\n";

            prevRecordWritten = recordWritten;
        }
        dialogText.text = dialogString;
    }

    void FixedUpdate()
    {
        rigidBody.useGravity = !canJump;

        Vector3 resultVelocity = Vector3.up * rigidBody.linearVelocity.y;

        float speed = sprintAction.IsPressed() ? runSpeed : walkSpeed;
        Vector2 moveValue = moveAction.ReadValue<Vector2>();
        moveValue *= speed;

        if (moveValue.magnitude > 0.5 && canJump)
        {
            if (!walkSource.isPlaying)
                walkSource.Play();
        }
        else
        {
            walkSource.Stop();
        }
        walkSource.pitch = sprintAction.IsPressed() ? 2f : 1f;

        Vector3 forwardVector = transform.rotation * Vector3.forward;
        Vector3 rightVector = transform.rotation * Vector3.right;
        resultVelocity += forwardVector * moveValue.y + rightVector * moveValue.x;

        if (canJump && jumpAction.IsPressed())
        {
            resultVelocity.y = JumpVelocity;
            jumpSource.Play();
        }

        rigidBody.linearVelocity = resultVelocity;
        canJump = false;
    }

    void OnCollisionStay(Collision collision)
    {
        foreach (var contact in collision.contacts)
            if (Vector3.Dot(contact.normal, Vector3.up) > Mathf.Cos(jumpAngle * Mathf.Deg2Rad))
            {
                canJump = true;
            }
    }

    public void Put()
    {
        Rigidbody body = ThingInArm.AddComponent<Rigidbody>();
        body.constraints = RigidbodyConstraints.FreezeRotation;
        ThingInArm.transform.parent = null;
        ThingInArm = null;
    }

    public void Take(Transform thing)
    {
        ThingInArm = thing;
        Rigidbody body;
        if (thing.TryGetComponent(out body))
            Destroy(body);
        thing.transform.parent = arm;
        thing.transform.localPosition = Vector3.zero;
        thing.transform.localRotation = Quaternion.identity;
    }

    public void Say(string text, string writer = null)
    {
        dialogRecords.AddLast(new DialogRecord
        {
            spawnTime = -1,
            writer = writer,
            text = text,
        });
    }

    public void CallPhone(Phone.State state, int audioIndex = -1, bool loop = false)
    {
        if (ThingInArm != null)
            Put();
        animationController.SetBool("ShowPhone", true);
        phone.SetState(state, audioIndex, loop);
    }

    public void LockInput(float atTime)
    {
        StartCoroutine(LockInputCoroutine(atTime));
    }

    IEnumerator LockInputCoroutine(float atTime)
    {
        moveAction.Disable();
        jumpAction.Disable();
        attackAction.Disable();
        interactAction.Disable();
        yield return new WaitForSeconds(atTime);
        moveAction.Enable();
        jumpAction.Enable();
        attackAction.Enable();
        interactAction.Enable();
        playerInputMap.Enable();
    }
}

