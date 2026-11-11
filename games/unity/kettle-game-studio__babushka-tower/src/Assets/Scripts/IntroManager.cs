using System.Collections;
using TMPro;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class IntroManager : MonoBehaviour
{
    public InputActionAsset actions;
    public TextMeshProUGUI text;
    public Image image;

    public Sprite[] sprites;
    private int idx = 0;
    private bool locked = false;

    InputAction jumpAction;
    InputAction attackAction;
    InputAction interactAction;

    void Start()
    {
        Debug.Log("Start");
        InputActionMap playerInputMap = actions.FindActionMap("Player");
        playerInputMap.Enable();
        jumpAction = playerInputMap.FindAction("Jump");
        attackAction = playerInputMap.FindAction("Attack");
        interactAction = playerInputMap.FindAction("Interact");

        image.sprite = sprites[idx];
    }

    void Update()
    {
        if (locked) return;

        bool phoneButton = attackAction.WasPressedThisFrame();
        bool armButton = interactAction.WasPressedThisFrame();

        if (armButton || phoneButton || jumpAction.WasPressedThisFrame())
        {
            idx += 1;

            text.text = "Press [E] for next page";
            if (idx >= sprites.Length)
            {
                SceneManager.LoadScene("Game", LoadSceneMode.Single);
            }

            else if (idx >= sprites.Length - 1)
            {
                text.text = "Press [E] to start game";
            }
            StartCoroutine(NextFrame());
        }
    }

    IEnumerator NextFrame()
    {
        locked = true;
        var wait = new WaitForSeconds(1f / 30);

        for (var i = 0; i <= 10; i++)
        {
            image.color = new Color(1f, 1f, 1f, 1f - i / 10f);
            yield return wait;
        }
        image.sprite = sprites[idx];

        for (var i = 0; i <= 10; i++)
        {
            image.color = new Color(1f, 1f, 1f, i / 10f);
            yield return wait;
        }
        locked = false;
    }
}
