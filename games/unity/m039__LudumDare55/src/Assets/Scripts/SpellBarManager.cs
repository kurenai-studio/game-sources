using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace LD55
{
    public class SpellBarManager : MonoBehaviour
    {
        public static SpellBarManager Instance;

        #region Inspector

        [SerializeField] SpellBar _Template;

        #endregion

        void Awake()
        {
            Instance = this;
        }

        void Start()
        {
            _Template.gameObject.SetActive(false);
        }

        public SpellBar GetSpellBar()
        {
            var spellBar = Instantiate(_Template, transform, false);
            spellBar.gameObject.SetActive(true);
            return spellBar;
        }

        public void ReleaseSpellBar(SpellBar spellBar)
        {
            Destroy(spellBar.gameObject);
        }
    }
}
