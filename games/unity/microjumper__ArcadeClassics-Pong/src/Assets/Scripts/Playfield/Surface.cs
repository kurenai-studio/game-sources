using System;
using BouncingBehaviors;
using UnityEngine;

namespace Playfield
{
    public enum SurfaceType
    {
        Wall,
        Paddle
    }

    public class Surface : MonoBehaviour, IBouncingBehaviorProvider
    {
        public IBounceBehavior BounceBehavior { get; private set; }
        public SurfaceType SurfaceType { get; private set; }

        [SerializeField]
        private SurfaceType surfaceType;

        private void Start()
        {
            switch (surfaceType)
            {
                case SurfaceType.Wall:
                    BounceBehavior = new WallBounce();
                    SurfaceType = SurfaceType.Wall;   
                    break;
                case SurfaceType.Paddle:
                    BounceBehavior = new PaddleBounce();
                    SurfaceType = SurfaceType.Paddle;  
                    break;
                default:
                    throw new ArgumentOutOfRangeException();
            }
        }
    }
}