using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

[RequireComponent(typeof(Button))]
public class MoveButton : MonoBehaviour
{

    TextMeshProUGUI title;
    TextMeshProUGUI reqs;
    Button button;
    System.Action callback;

    void Start()
    {
        button = GetComponent<Button>();
        button.onClick.AddListener(OnClick);
        title = transform.GetChild(0).GetComponent<TextMeshProUGUI>();
        reqs = transform.GetChild(1).GetComponent<TextMeshProUGUI>();
    }

    void OnClick()
    {
        callback?.Invoke();
    }

    public void Enable(CustomTile.TileInfo ti, bool rest, bool enabled, System.Action callback)
    {
        this.callback = callback;
        title.text = ti.GetTitle();
        string text = "Takes: ";
        if (rest)
        {
            text += "<sprite name=Time>";
        }
        else
        {
            if (ti.energy > 10)
            {
                gameObject.SetActive(false);
                return;
            }
            for (int i = 0; i < ti.energy; i++)
            {
                text += "<sprite name=Energy>";
            }
        }
        for (int i = 0; i < ti.food; i++)
        {
            text += "<sprite name=Food>";
        }
        reqs.text = text;
        button.interactable = enabled;
        gameObject.SetActive(true);
    }

    public void Disable()
    {
        gameObject.SetActive(false);
    }
}
