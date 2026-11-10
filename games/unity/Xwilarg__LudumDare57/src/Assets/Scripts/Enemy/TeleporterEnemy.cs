using System.Collections;
using UnityEngine;

namespace LudumDare57.Enemy
{
    public class TeleporterEnemy : AEnemy
    {
        [SerializeField]
        private GameObject _hintPrefab;

        private GameObject _hintInstance;
        public override bool IsBad => true;

        public override void DoAction()
        {
            StartCoroutine(WaitAndTeleport());
        }

        private IEnumerator WaitAndTeleport()
        {
            _hintInstance = Instantiate(_hintPrefab, _target.transform.position, Quaternion.identity);
            yield return new WaitForSeconds(.75f);

            if (!_isStunned) transform.position = _hintInstance.transform.position;
            Destroy(_hintInstance);
        }

        public override void OnDestroy()
        {
            if (_hintInstance != null) Destroy(_hintInstance);
        }

        public override float DistanceSeeMultiplier => .66f;
    }
}