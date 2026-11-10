using UnityEngine;

[RequireComponent(typeof(BaseStats), typeof(Rigidbody))]
public class EnemyController : MonoBehaviour
{
    [SerializeField]
    private CardType _dropCard;

    private BaseStats _stats;
    private Coroutine _damageCoroutine;

    private void Awake()
    {
        _stats = GetComponent<BaseStats>();
    }

   public void DropLoot()
    {
        MessageQueue.Instance.SendMessage(new CardDroppedMessage
        {
            Type = _dropCard,
            Position = transform.position
        });

        gameObject.SetActive(false);
    }

    private void Update()
    {
        transform.position = Vector3.MoveTowards(
            transform.position,
            PlayerController.Instance.transform.position,
            _stats.MovementSpeed * Time.deltaTime
        );
    }

    private void OnCollisionEnter(Collision collision)
    {
        if (!gameObject.activeInHierarchy)
        {
            return;
        }

        if (collision.collider.CompareTag("Player"))
        {
            Debug.Log($"EnemyController.OnCollisionEnter: {collision.collider.name}");
            _damageCoroutine = StartCoroutine(_stats.DamageOverTime(collision.gameObject));
        }
    }

    private void OnCollisionExit(Collision collision)
    {
        if (collision.collider.CompareTag("Player"))
        {
            Debug.Log($"EnemyController.OnCollisionExit: {collision.collider.name}");
            StopDamageOverTime();
        }
    }

    private void StopDamageOverTime()
    {
        if (_damageCoroutine != null)
        {
            StopCoroutine(_damageCoroutine);
            _damageCoroutine = null;
        }
    }
}
