using JGM.Gameplay;
using JGM.Gameplay.Wallet;
using TMPro;
using UnityEngine;

namespace JGM.UI.Wallet
{
    public class PlayerWalletView : MonoBehaviour
    {
        [SerializeField] 
        private TextMeshProUGUI coinsAmountText;
        
        private PlayerWallet playerWallet;

        private void Awake()
        {
            playerWallet = ServiceLocator.Instance.Get<PlayerWallet>();
            coinsAmountText.text = playerWallet.Coins.ToString("000");
        }

        private void OnEnable()
        {
            playerWallet.OnWalletChange += OnWalletChange;
        }

        private void OnDisable()
        {
            playerWallet.OnWalletChange -= OnWalletChange;
        }

        private void OnWalletChange(int coins)
        {
            coinsAmountText.text = coins.ToString("000");
        }
    }
}
