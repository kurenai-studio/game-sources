using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace LD55
{
    public class TutorialZone : MonoBehaviour
    {
        #region Inspector

        [SerializeField] float _Radius = 10f;

        #endregion

        bool _activated = false;

        bool _wasInside = false;

        void OnDrawGizmosSelected()
        {
            Gizmos.color = Color.blue;
            Gizmos.DrawWireSphere(transform.position, _Radius);
        }

        void Update()
        {
            ProcessUpdate();
        }

        void ProcessUpdate()
        {
            if (Player.Instance == null)
                return;

            if (_activated)
                return;

            var playerPosition = Player.Instance.transform.position;
            playerPosition.y = 0;
            var myPosition = transform.position;
            playerPosition.y = 0;

            var isInside = Vector3.Distance(myPosition, playerPosition) < _Radius;

            if (!_wasInside && isInside)
            {
                MainUI.Instance.ShowTutorialInfo();
            } else if (_wasInside && !isInside)
            {
                _activated = true;
                MainUI.Instance.HideTutorialInfo();
            }

            _wasInside = isInside;
        }
    }
}
