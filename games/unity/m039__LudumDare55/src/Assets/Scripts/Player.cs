using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace LD55
{

    public class Player : MonoBehaviour
    {
        public static Player Instance;

        #region Inspector

        [SerializeField] float _Speed = 5f;

        [SerializeField] Transform _Visual;

        [SerializeField] float _Raidus = 0.5f;

        #endregion

        static readonly Collider[] s_Buffer = new Collider[64];

        readonly PlayerInput _input = new();

        readonly List<Ingredient> _ingredients = new();

        Altar _activeObject;

        EnemyZone _currentEnemyZone;

        CharacterController _characterController;

        public EnemyZone CurrentEnemyZone => _currentEnemyZone;

        void Awake()
        {
            Instance = this;

            _characterController = GetComponent<CharacterController>();
        }

        void Update()
        {
            ProcessInput();
        }

        void FixedUpdate()
        {
            ProcessEnemies();
        }

        void ProcessEnemies()
        {
            var count = Physics.OverlapSphereNonAlloc(transform.position, _Raidus, s_Buffer);
            if (count > 0)
            {
                for (int i = 0; i < count; i++)
                {
                    if (s_Buffer[i].GetComponentInParent<Enemy>() is Enemy enemy)
                    {
                        GameController.Instance.LoseGame();
                        return;
                    }
                }
            }
        }

        void ProcessInput()
        {
            var move = _input.GetMove();
            if (move.sqrMagnitude > 0)
            {
                var offset = new Vector3(move.x, 0, move.y);
                _Visual.rotation = Quaternion.LookRotation(offset, Vector3.up);
                _characterController.Move(offset * _Speed * Time.deltaTime);
            }

            if (_activeObject != null &&
                _input.ActionKey() &&
                !_activeObject.IsActivated &&
                _activeObject.Ingredients.All((ingredient) => _ingredients.Contains(ingredient)))
            {  
                _activeObject.Activate();

                if (_activeObject.IsActivated)
                {
                    foreach (var ingredient in _activeObject.Ingredients)
                    {
                        _ingredients.Remove(ingredient);
                    }

                    MainUI.Instance.ShowInventory(_ingredients);
                    MainUI.Instance.HideAltarActivationInfo();
                }
            }
        }

        public void OnEnter(Altar altar)
        {
            _activeObject = altar;

            if (_activeObject.IsActivated)
                return;

            if (altar.Ingredients.All((ingredient) => _ingredients.Contains(ingredient)))
            {
                MainUI.Instance.ShowAltarActivationInfo();
            } else
            {
                MainUI.Instance.ShowIngredientsInfo(altar.Ingredients);
            }
        }

        public void OnEnter(Ingredient ingredient)
        {
            _ingredients.Add(ingredient);
            ingredient.Consume();

            MainUI.Instance.ShowInventory(_ingredients);
        }

        public void OnEnter(EnemyZone enemyZone)
        {
            _currentEnemyZone = enemyZone;
        }

        public void OnExit(EnemyZone enemyZone)
        {
            if (_currentEnemyZone == enemyZone)
            {
                _currentEnemyZone = null;
            }
        }

        public void OnExit(Altar altar)
        {
            if (altar == _activeObject)
            {
                _activeObject = null;
                MainUI.Instance.HideAltarActivationInfo();
                MainUI.Instance.HideIngredientsInfo();
            }
        }
    }

}
