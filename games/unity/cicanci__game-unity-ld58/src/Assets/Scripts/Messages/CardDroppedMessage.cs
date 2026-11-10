using UnityEngine;

public class CardDroppedMessage : IMessage
{
    public CardType Type;
    public Vector3 Position;
}
