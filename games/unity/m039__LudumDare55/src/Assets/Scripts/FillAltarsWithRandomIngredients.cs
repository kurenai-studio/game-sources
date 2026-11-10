using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace LD55
{
    public class FillAltarsWithRandomIngredients : MonoBehaviour
    {
        #region Inspector

        [SerializeField] Ingredient[] _Ingredients;

        [SerializeField] Altar[] _Altar;

        #endregion

        void Start()
        {
            Fill();
        }

        void Fill()
        {
            if (_Ingredients == null || _Altar == null || _Ingredients.Length != _Altar.Length)
            {
                return;
            }

            var ingredients = new List<Ingredient>(_Ingredients);
            var colors = _Ingredients.Select(i => i.color).ToList();

            var index = 0;

            while (colors.Count > 0)
            {
                var i = Random.Range(0, colors.Count);
                var color = colors[i];
                colors.RemoveAt(i);

                _Ingredients[index].color = color;
                index++;
            }

            index = 0;

            while (ingredients.Count > 0)
            {
                var i = Random.Range(0, ingredients.Count);
                var ingredient = ingredients[i];
                ingredients.RemoveAt(i);

                _Altar[index].Ingredients = new Ingredient[]
                {
                    ingredient
                };
                index++;
            }
        }
    }
}
