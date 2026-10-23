using UnityEngine;

namespace Playfield
{
    public enum Side
    {
        Left,
        Right
    }
    
    public class Playfield : MonoBehaviour
    {
        [SerializeField]
        private GameObject topWall;
        [SerializeField]
        private GameObject bottomWall;

        public Boundary VerticalBoundary { get; private set; }

        private void Awake()
        {
            VerticalBoundary = new Boundary(bottomWall.transform.position.y, topWall.transform.position.y);
        }
    }
}

