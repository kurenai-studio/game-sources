using UnityEngine;

public class SquadCollisions : MonoBehaviour
{
    public EventSquadCapturedFlag EventSquadCapturedFlag = new EventSquadCapturedFlag();

    private Squad squad;

    private void Awake()
    {
        this.squad = GetComponent<Squad>();
    }

    private void OnCollisionEnter2D(Collision2D collision)
    {
        if ((collision.gameObject.tag == "Player" || collision.gameObject.tag == "AI") && collision.gameObject.tag != this.squad.gameObject.tag)
        {
            Squad hitSquad = collision.gameObject.GetComponent<Squad>();
            hitSquad.TakeDamage(Formulas.CalculateDamage(this.squad, hitSquad));
            this.squad.ResetSquadAttackingState();
        }
    }

    private void OnTriggerEnter2D(Collider2D collision)
    {
        if (collision.tag == "Flag")
        {
            EventSquadCapturedFlag.Dispatch(this.squad);
        }
    }
}
