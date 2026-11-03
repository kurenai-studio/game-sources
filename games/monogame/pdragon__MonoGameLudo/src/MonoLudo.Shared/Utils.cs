using Microsoft.Xna.Framework;
//using System.Numerics;
using System.Text.RegularExpressions;
using MonoLudo.Core;
using System;

namespace LudoGame.Helpers
{
    internal class Utils
    {

        float deltaTime = (float)Config.DeltaTime;

        public static short ConvertStringToShort(string number)
        {
            short returnIntVal = 0;
            
            if (!string.IsNullOrEmpty(number))
            {
                var cleanNumber = Regex.Replace(number, @"\s+", "");

                try
                {
                    if (short.TryParse(cleanNumber, out short ux))
                    {
                        returnIntVal = ux;
                    }
                }
                catch (Exception exp)
                {
                    var ex = exp;
                }
            }
            else
            {
                returnIntVal = 0;
            }
            

            //Console.WriteLine("returnIntVal: " + returnIntVal);
            return returnIntVal;
        }
    }

    public static class StringExtension
    {
        public static Vector2? GetVector2(this string str)
        {
            if (string.IsNullOrEmpty(str))
            {
                return null;
            }
            string[] strArr = str.Split(',');
            if (strArr.Length < 2)
            {
                return null;
            }
            if (string.IsNullOrEmpty(strArr[0]) || string.IsNullOrEmpty(strArr[1]))
            {
                return null;
            }
            bool res1 = int.TryParse(strArr[0], out int r1);
            bool res2 = int.TryParse(strArr[1], out int r2);
            if(!res1 || !res2)
            {
                return null;
            }

            return new Vector2(r1,r2);
        }
    }
}
