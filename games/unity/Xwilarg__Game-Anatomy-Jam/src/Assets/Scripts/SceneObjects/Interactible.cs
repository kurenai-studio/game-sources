using AnatomyJam.SceneObjects.Station;
using System;
using UnityEngine;
using UnityEngine.Events;

namespace AnatomyJam.SceneObjects
{
    public class Interactible : MonoBehaviour
    {
        [SerializeField]
        private UnityEvent _onAction;

        [SerializeField]
        private AStation _associatedStation;

        public bool IsValid(SceneObject obj)
        {
            if (_associatedStation == null)
            {
                return obj == null;
            }
            if (obj == null)
            {
                return false;
            }
            if (!_associatedStation.IsValid(obj))
            {
                return false;
            }
            if (_associatedStation is TimerStation timer)
            {
                if (timer.IsTimerActive)
                {
                    return false;
                }
            }
            return obj != null && _associatedStation.GetRecipe(obj);
        }

        public void AddListener(Action callback)
        {
            _onAction.AddListener(new(callback));
        }

        public void Invoke()
        {
            _onAction?.Invoke();
        }

        private static int _id = 0;

        private int _myId = _id++;

        public static bool operator ==(Interactible a, Interactible b)
        {
            if (a is null)
            {
                return b is null;
            }
            if (b is null)
            {
                return false;
            }
            return a._myId == b._myId;
        }

        public static bool operator !=(Interactible a, Interactible b)
            => !(a == b);

        public override bool Equals(object obj)
        {
            if (this is null)
            {
                return obj is null;
            }
            if (obj is null || obj is not Interactible inc)
            {
                return false;
            }
            return _myId == inc._myId;
        }

        public override int GetHashCode()
            => _myId.GetHashCode();
    }
}
