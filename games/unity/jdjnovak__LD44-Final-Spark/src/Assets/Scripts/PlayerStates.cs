using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerStates : MonoBehaviour
{
    public enum States {
        FullCharge,
        HighCharge,
        HalfCharge,
        LowCharge,
        NoCharge,
        Dead = -1
    }
}
