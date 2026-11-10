using UnityEngine;

public class CardDropSpawner : MonoBehaviour
{
    [SerializeField]
    private ObjectSpawn _fireCardSpawner;

    [SerializeField]
    private ObjectSpawn _iceCardSpawner;

    private void OnEnable()
    {
        MessageQueue.Instance.AddListener<CardDroppedMessage>(OnCardDropped);
    }

    private void OnDisable()
    {
        MessageQueue.Instance.RemoveListener<CardDroppedMessage>(OnCardDropped);
    }

    private void OnCardDropped(CardDroppedMessage message)
    {
        Debug.Log($"CardDroppedMessage: {message.Type}");

        switch (message.Type)
        {
            case CardType.Fire:
                _fireCardSpawner.SpawnObject().transform.position = message.Position;
                break;
            case CardType.Ice:
                _iceCardSpawner.SpawnObject().transform.position = message.Position;
                break;
            default:
                break;
        }
    }
}
