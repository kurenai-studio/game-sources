using LudumDare57.Player;
using UnityEngine;

namespace LudumDare57.Prop
{
    public class ExitDoor : MonoBehaviour
    {
        [SerializeField]
        private GameObject _help;

        private void OnTriggerEnter2D(Collider2D collision)
        {
            if (collision.CompareTag("Player"))
            {
                collision.GetComponent<PlayerController>().IsOnExit = true;
                _help.SetActive(true);
            }
        }

        private void OnTriggerExit2D(Collider2D collision)
        {
            if (collision.CompareTag("Player"))
            {
                collision.GetComponent<PlayerController>().IsOnExit = false;
                _help.SetActive(false);
            }
        }
    }
}