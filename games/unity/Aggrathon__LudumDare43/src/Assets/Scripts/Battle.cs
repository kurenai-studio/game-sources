using UnityEngine;
using System.Collections;

public class Battle : MonoBehaviour
{
	public float intervals = 1f;
	public Transform defenderMorale;
	public Transform attackerMorale;

	IBattleParticipant a;
	IBattleParticipant b;
	float am;
	float bm;

	public void Setup(IBattleParticipant a, IBattleParticipant b)
	{
		transform.position = a.position;
		this.a = a;
		this.b = b;
		Vector3 dir = (b.position - a.position).normalized;
		float sign = dir.x < 0? -1f: 1f;
		transform.rotation = Quaternion.Euler(0, 0, sign*Mathf.Asin(dir.y)*Mathf.Rad2Deg);
		if (sign < 0)
		{
			Transform tmp = defenderMorale;
			defenderMorale = attackerMorale;
			attackerMorale = tmp;
		}
		UpdateMorale(true);
		StartCoroutine(Fight());
	}

	IEnumerator Fight()
	{
		while (true)
		{
			yield return new WaitForSeconds(intervals);
			int ad = a.GetDamage();
			int bd = b.GetDamage();
			bool af = a.DoDamage(bd);
			bool bf = b.DoDamage(ad);
			if (!af || !bf)
			{
				a.EndCombat(!bf);
				b.EndCombat(!af);
				Destroy(gameObject);
				break;
			}
			UpdateMorale(false);
		}
	}

	void UpdateMorale(bool reset)
	{
		float a = this.a.GetMorale();
		float b = this.b.GetMorale();
		if (reset)
		{
			am = a;
			bm = b;
		}
		else
		{
			am = Mathf.Max(am, a);
			bm = Mathf.Max(bm, b);
		}
		if (am == 0) am = 1f;
		if (bm == 0) bm = 1f;
		Vector3 scale = attackerMorale.localScale;
		scale.y = a / am;
		attackerMorale.localScale = scale;
		scale = defenderMorale.localScale;
		scale.y = b / bm;
		defenderMorale.localScale = scale;
	}

}

public interface IBattleParticipant
{
	Vector3 position { get; }
	float GetMorale();
	int GetDamage();
	bool DoDamage(int damage);
	void EndCombat(bool won);
}