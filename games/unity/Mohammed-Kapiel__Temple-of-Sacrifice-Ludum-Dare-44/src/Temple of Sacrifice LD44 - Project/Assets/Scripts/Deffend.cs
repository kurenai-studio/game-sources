using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;

public class Deffend : MonoBehaviour, ISelectHandler
{
    public GameplayManager gameplayManager;

    public void OnSelect(BaseEventData eventData)
    {
        gameplayManager.DeffendUnit();
    }
}
