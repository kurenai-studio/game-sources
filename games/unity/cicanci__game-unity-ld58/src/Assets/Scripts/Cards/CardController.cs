using System;
using UnityEngine;

public class CardController : MonoBehaviour
{
    [SerializeField]
    private float _rotationSpeed = 90f;

    [SerializeField]
    private CardType _cardType;

    public void PickUpCard()
    {
        MessageQueue.Instance.SendMessage(new CardPickedUpMessage 
        { 
            Quantity = 1, 
            Type = _cardType
        });

        gameObject.SetActive(false);
    }

    private void Update()
    {
        transform.Rotate(Vector3.up * _rotationSpeed * Time.deltaTime);
    }
}
