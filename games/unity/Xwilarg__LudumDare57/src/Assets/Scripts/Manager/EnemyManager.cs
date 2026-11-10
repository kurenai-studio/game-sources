using LudumDare57.Enemy;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace LudumDare57.Manager
{
    public class EnemyManager : MonoBehaviour
    {
        public static EnemyManager Instance { private set; get; }

        private readonly List<AEnemy> _enemies = new();

        [SerializeField]
        private SpriteRenderer _shopSr;

        [SerializeField]
        private Sprite _emptyShop;

        private int AmountGood { set; get; }
        private int AmountBad { set; get; }

        public bool OnlyKillBads { set; get; }

        private void Awake()
        {
            Instance = this;
        }

        public void Register(AEnemy e)
        {
            _enemies.Add(e);
            if (!e.IsBad) AmountGood++;
            else AmountBad++;
        }

        public void Unregister(GameObject go)
        {
            _enemies.RemoveAll(x => x.gameObject.GetInstanceID() == go.GetInstanceID());
            if (AreAllGoodDead) _shopSr.sprite = _emptyShop;
        }

        public bool DidKillAnyGood => _enemies.Count(x => !x.IsBad) != AmountGood;
        public bool DidKillAnyBad => _enemies.Count(x => x.IsBad) != AmountBad;
        public bool AreAllGoodDead => _enemies.Count(x => !x.IsBad) == 0;

        public bool AreBadEnemiesAlive => _enemies.Any(x => x.IsBad);
        public bool AreMostDead => _enemies.Count < AmountGood / 2f;
    }
}