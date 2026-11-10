using System.Collections;
using UnityEngine;

public class BaseStats : MonoBehaviour
{
    public float Health;
    public float Damage;
    public float AttackCooldown;
    public float MovementSpeed;
    public AttributeTypes Attributes;

    public float GetMultiplier(BaseStats other)
    {
        if (Attributes.HasFlag(AttributeTypes.FireAttack))
        {
            if (other.Attributes.HasFlag(AttributeTypes.FireResistence))
            {
                return 0.5f;
            }

            if (other.Attributes.HasFlag(AttributeTypes.IceResistence))
            {
                return 2f;
            }
        }

        if (Attributes.HasFlag(AttributeTypes.IceAttack))
        {
            if (other.Attributes.HasFlag(AttributeTypes.IceResistence))
            {
                return 0.5f;
            }

            if (other.Attributes.HasFlag(AttributeTypes.FireResistence))
            {
                return 2f;
            }
        }

        return 1f;
    }

    public IEnumerator DamageOverTime(GameObject other)
    {
        BaseStats otherStats = other.GetComponent<BaseStats>();

        if (otherStats == null)
        {
            yield break;
        }

        Debug.Log($"DamageOverTime: {other.name}. Heath = {otherStats.Health}");

        while (otherStats.Health > 0)
        {
            float multiplier = GetMultiplier(otherStats);

            otherStats.Health -= Damage * multiplier;
            Debug.Log($"DamageOverTime: {other.name} tooke {Damage} damage with {multiplier}x multiplier. Heath = {otherStats.Health}");

            var player = other.GetComponent<PlayerController>();
            if (player != null)
            {
                MessageQueue.Instance.SendMessage(new HealthUpdateMessage() { Amount = otherStats.Health });
            }

            if (otherStats.Health <= 0)
            {
                Debug.Log($"DamageOverTime: {other.name} is dead.");

                var enemy = other.GetComponent<EnemyController>();
                if (enemy != null)
                {
                    other.GetComponent<EnemyController>().DropLoot();
                }

                if (player != null)
                {
                    MessageQueue.Instance.SendMessage(new GameOverMessage());
                }

                yield break;
            }

            yield return new WaitForSeconds(otherStats.AttackCooldown);
        }
    }
}
