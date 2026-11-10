using UnityEngine;
using UnityEngine.UI;

public enum SheepIconState
{
    Default,
    Dead,
    Success
}

public class SheepIcon : MonoBehaviour
{
    public Sprite defaultSheepIcon;
    public Sprite deadSheepIcon;
    public Sprite successSheepIcon;

    private Image UiImage;
    public int id = 0;

    private SpriteRenderer spriteRenderer;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        spriteRenderer = GetComponent<SpriteRenderer>();
        UiImage = GetComponent<Image>();

        SetState(SheepIconState.Default);
    }

    public void SetState(SheepIconState state)
    {
        switch (state)
        {
            case SheepIconState.Default:
                UiImage.sprite = defaultSheepIcon;
                break;
            case SheepIconState.Dead:
                UiImage.sprite = deadSheepIcon;
                break;
            case SheepIconState.Success:
                UiImage.sprite = successSheepIcon;
                break;
        }
    }

    // Update is called once per frame
    void Update() { }
}
