using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using System;

public class ManaOrb : GridOrb
{
    public Color[] colors;
    Color color = Color.white;
    public System.Action<ManaOrb> OnClicked;
    
    public void SetRandomColor(int max)
    {
        max = Mathf.Clamp(max, 0, colors.Length - 1);
        OrbTypeID = UnityEngine.Random.Range(0, max);
        color = colors[OrbTypeID];
        GetComponent<Image>().color = color;
    }
    
    public void OnPointerClick()
    {
        if (OrbTypeID != -1) //Not dead
            OnClicked(this);
    }

    public void OnPointerEnter()
    {
        if (OrbTypeID != -1) //Not dead
            GameBoard.Instance.HighlightSelected(this);
    }
    public void OnPointerExit()
    {
        GameBoard.Instance.LowlightSelected(this);
        //SetPointerHighlight(false);
    }

    public void SetPointerHighlight(bool selected)
    {
        Outline outline = GetComponent<Outline>();
        if (selected)
        {
            outline.effectDistance = new Vector2(4,4);
        }
        else
        {
            outline.effectDistance = new Vector2(1,1);
        }
    }

    internal void Setdead()
    {
        OrbTypeID = -1; //Dead
        color = Color.black;
        GetComponent<Image>().color = color;
    }
}