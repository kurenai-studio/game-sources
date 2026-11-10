using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace LD55
{
    public class SpawnZone : MonoBehaviour
    {
        #region Inspector

        [SerializeField] Enemy[] _Enemies;

        #endregion

        bool _activated = false;

        void Start()
        {
            if (_Enemies != null)
            {
                foreach (var enemy in _Enemies)
                {
                    if (enemy != null)
                    {
                        enemy.gameObject.SetActive(false);
                    }
                }
            }
        }

        void OnTriggerEnter(Collider other)
        {
            if (_activated)
                return;

            if (other.GetComponentInParent<Player>() is Player player)
            {
                if (_Enemies != null)
                {
                    foreach (var enemy in _Enemies)
                    {
                        if (enemy != null)
                        {
                            enemy.gameObject.SetActive(true);
                        }
                    }
                }

                _activated = true;
            }
        }
    }
}
