using LudumDare57.Player;
using System;
using System.Collections.Generic;
using System.Linq;
using TMPro;
using UnityEngine;

namespace LudumDare57.Manager
{
    public class PlayerManager : MonoBehaviour
    {
        public static PlayerManager Instance { private set; get; }

        [SerializeField]
        private Camera _cam;
        public Camera Camera => _cam;

        private readonly List<PlayerController> _players = new();

        [SerializeField]
        private Transform _targetFollow;

        [SerializeField]
        private TMP_Text _moneyText;

        [SerializeField]
        private int _baseMoney;

        public int Money { private set; get; }

        private void Awake()
        {
            Instance = this;
        }

        private void Start()
        {
            GainMoney(_baseMoney);
        }

        private void Update()
        {
            if (_players.Count == 0) return;

            _targetFollow.position = _players.Select(x => x.transform.position).Aggregate((a, b) => a + b) / _players.Count;
        }

        public void GainMoney(int amount)
        {
            Money += amount;
            _moneyText.text = $"{Money}";
            ShopManager.Instance.UpdateShopUI(Money);
        }

        public void Register(PlayerController pc)
        {
            _players.Add(pc);
        }

        public PlayerController GetClosest(Vector2 target)
            => _players.OrderBy(p => Mathf.Pow(target.x - p.transform.position.x, 2) + Mathf.Pow(target.y - p.transform.position.y, 2)).FirstOrDefault();

        public void ToggleSkin()
        {
            ForEach(x => x.ToggleSkin());
        }

        public void ForEach(Action<PlayerController> a)
        {
            foreach (var p in _players)
            {
                a(p);
            }
        }
    }
}