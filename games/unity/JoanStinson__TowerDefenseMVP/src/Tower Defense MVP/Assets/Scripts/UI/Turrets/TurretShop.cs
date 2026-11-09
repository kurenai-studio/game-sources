using JGM.Gameplay;
using JGM.Gameplay.Turrets;
using JGM.Gameplay.Wallet;
using UnityEngine;

namespace JGM.UI.Turrets
{
    public class TurretShop : MonoBehaviour
    {
        [SerializeField] private TurretList turretList;
        [SerializeField] private TurretCard turretCardPrefab;
        [SerializeField] private Transform turretCardsParent;

        private PlayerWallet playerWallet;
        private TurretSpawner turretSpawner;
        private Camera mainCamera;

        private void Start()
        {
            var serviceLocator = ServiceLocator.Instance;
            playerWallet = serviceLocator.Get<PlayerWallet>();
            turretSpawner = serviceLocator.Get<TurretSpawner>();
            mainCamera = serviceLocator.Get<Camera>();
            SpawnTurretCards();
        }

        private void SpawnTurretCards()
        {
            foreach (var turret in turretList.Turrets)
            {
                var turretCard = Instantiate(turretCardPrefab, turretCardsParent, false);
                var turretCardModel = new TurretCardModel(turret.Key, turret.Value.Price, turret.Value.CardColor);
                turretCard.Initialize(turretCardModel, this);
                turretCard.RefreshCardIsAvailable(playerWallet.Coins);
                playerWallet.OnWalletChange += turretCard.RefreshCardIsAvailable;
            }
        }

        public void OnTurretCardDropped(TurretCardModel model, Vector2 position)
        {
            var ray = mainCamera.ScreenPointToRay(position);

            if (Physics.Raycast(ray, out RaycastHit hit, 1000f))
            {
                var turret = turretList.GetTurretById(model.Id);
                turretSpawner.Spawn(turret, hit.point);
                playerWallet.RemoveCoins(model.Price);
            }
            else
            {
                Debug.LogWarning("Invalid turret placement");
            }
        }
    }
}
