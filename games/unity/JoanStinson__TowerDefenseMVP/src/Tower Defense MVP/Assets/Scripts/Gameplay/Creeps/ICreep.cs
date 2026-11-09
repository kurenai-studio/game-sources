using JGM.Gameplay.Base;
using UnityEngine;

namespace JGM.Gameplay.Creeps
{
    public interface ICreep
    {
        GameObject GameObject { get; }
        int CoinReward { get; }

        void Initialize(CreepSpawner creepSpawner, PlayerBase playerBase);
    }
}
