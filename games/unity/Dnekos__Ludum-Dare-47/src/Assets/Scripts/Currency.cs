using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Currency
{
    public KeyValuePair<float, int> value;
    public Currency(float number, int power)
    {
        value = new KeyValuePair<float, int>(number, power);
    }
    public Currency(float number)
    {
        float newnum = number;
        int pow = 0;
        while ((int)newnum.ToString().Length == 1)
        {
            newnum = number / 10;
            pow++;
        }
            value = new KeyValuePair<float, int>((int)(newnum * 100) / 100, pow);
    }
    public string DisplayNumber()
    {
        if (value.Value < 6)
            return (value.Key * value.Value).ToString();
        return value.Key + " * 10^" + value.Value;
    }

    public Currency Pow(float power) // sacrifices accuracy when dealing with decimal powers for simplicity, its prob fine?
        => new Currency(Mathf.Pow(value.Key, power), Mathf.RoundToInt(Mathf.Pow(value.Value, power)));

    public static Currency operator *(Currency a, float b)
        => (a.value.Key * b > 10f) ? new Currency((int)(a.value.Key * b * 100) / 1000, a.value.Value + 1) 
        : new Currency((int)(a.value.Key * b * 100) / 100, a.value.Value);

    public static Currency operator *(Currency a, Currency b)
    => (a.value.Key * b.value.Key > 10f) ? new Currency((int)(a.value.Key * b.value.Key * 100) / 1000, a.value.Value + b.value.Value + 1) 
        : new Currency((int)(a.value.Key * b.value.Key * 100) / 100, a.value.Value + b.value.Value);

    public static Currency operator +(Currency a, Currency b)
    {
        if (a.value.Value == b.value.Value) // equal powers
        {
            if (a.value.Value + b.value.Value > 10)
                return new Currency(((int)(a.value.Key + b.value.Key)*100) / 1000, a.value.Value + 1);
            else
                return new Currency(((int)(a.value.Key + b.value.Key) * 100) / 100, a.value.Value);
        }
        if (a.value.Value - b.value.Value < 3 && a.value.Value - b.value.Value > 0) // a is bigger but withing signifigant range
        {
            float resultant = a.value.Key + (b.value.Key / Mathf.Pow(10, a.value.Value - b.value.Value));
            if (resultant > 10)
                return new Currency(((int)(resultant * 100) / 1000), a.value.Value + 1);
            else
                return new Currency(((int)(resultant * 100) / 100), a.value.Value);
        }
        if (b.value.Value - a.value.Value < 3 && b.value.Value - a.value.Value > 0) // b is bigger but withing signifigant range
        {
            float resultant = b.value.Key + (a.value.Key / Mathf.Pow(10, b.value.Value - a.value.Value));
            if (resultant > 10)
                return new Currency(((int)(resultant * 100) / 1000), b.value.Value + 1);
            else
                return new Currency(((int)(resultant * 100) / 100), b.value.Value);
        }

        if (a.value.Value > b.value.Value)
            return a;
        else
            return b;
    }
    public static Currency operator -(Currency a, Currency b)
    {
        if (a.value.Value == b.value.Value) // equal powers
        {
            if (a.value.Value - b.value.Value < 0)
                return new Currency(((int)(a.value.Key + b.value.Key) * 1000) / 100, a.value.Value - 1);
            else
                return new Currency(((int)(a.value.Key + b.value.Key) * 100) / 100, a.value.Value);
        }
        if (a.value.Value - b.value.Value < 3 && a.value.Value - b.value.Value > 0) // a is bigger but withing signifigant range
        {
            float resultant = a.value.Key - (b.value.Key / Mathf.Pow(10, a.value.Value - b.value.Value));
            if (resultant < 0)
                return new Currency(((int)(resultant * 1000) / 100), a.value.Value - 1);
            else
                return new Currency(((int)(resultant * 100) / 100), a.value.Value);
        }
        if (b.value.Value - a.value.Value < 3 && b.value.Value - a.value.Value > 0) // b is bigger but withing signifigant range
        {
            float resultant = b.value.Key - (a.value.Key / Mathf.Pow(10, b.value.Value - a.value.Value));
            if (resultant < 0)
                return new Currency(((int)(resultant * 1000) / 000), b.value.Value - 1);
            else
                return new Currency(((int)(resultant * 100) / 100), b.value.Value);
        }

        if (a.value.Value > b.value.Value)
            return a;
        else
            return b;
    }


    public static bool operator <(Currency a, Currency b)
    {
        if (a.value.Value < b.value.Value)
            return true;
        else if (a.value.Value == b.value.Value && a.value.Key < b.value.Key)
            return true;
        return false;
    }
    public static bool operator >(Currency a, Currency b)
    {
        if (a.value.Value > b.value.Value)
            return true;
        else if (a.value.Value == b.value.Value && a.value.Key > b.value.Key)
            return true;
        return false;
    }
    public static bool operator <=(Currency a, Currency b)
    {
        if (a.value.Value <= b.value.Value)
            return true;
        else if (a.value.Value == b.value.Value && a.value.Key <= b.value.Key)
            return true;
        return false;
    }
    public static bool operator >=(Currency a, Currency b)
    {
        if (a.value.Value >= b.value.Value)
            return true;
        else if (a.value.Value == b.value.Value && a.value.Key >= b.value.Key)
            return true;
        return false;
    }
}
