using LudumDare57.Manager;
using TMPro;
using UnityEngine;

namespace LudumDare57.Prop
{
    public class ShopHelp : MonoBehaviour
    {
        [SerializeField]
        private TMP_Text _help;

        private void Awake()
        {
            _help.gameObject.SetActive(false);
        }

        private void OnTriggerEnter2D(Collider2D collision)
        {
            if (collision.CompareTag("Player"))
            {
                _help.gameObject.SetActive(true);

                if (!EnemyManager.Instance.DidKillAnyGood && !EnemyManager.Instance.DidKillAnyBad) _help.text = "You're here amazing! Thanks for helping cleaning the oculi!";
                else if (EnemyManager.Instance.DidKillAnyGood)
                {
                    if (EnemyManager.Instance.AreAllGoodDead) _help.text = string.Empty;
                    else if (EnemyManager.Instance.AreBadEnemiesAlive)
                    {
                        if (!EnemyManager.Instance.DidKillAnyBad) _help.text = "You're doing well, don't forget all oculi aren't bad tho!";
                        else if (EnemyManager.Instance.AreBadEnemiesAlive) _help.text = "Some bad oculi are still there, keep it up!";
                        else if (EnemyManager.Instance.AreMostDead) _help.text = "Don't forget, only kill the good ones, right?";
                        else _help.text = "You did it, good job!";
                    }
                }
                else _help.text = "You're doing amazing, keep it up!";
            }
        }

        private void OnTriggerExit2D(Collider2D collision)
        {
            if (collision.CompareTag("Player"))
            {
                _help.gameObject.SetActive(false);
            }
        }
    }
}