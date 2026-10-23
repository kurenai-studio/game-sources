using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Escapeaway.Source.Objects.Level.Boss
{
    internal class Boss
    {
        public int health, maxHealth;
        private int previousHealth, previousMaxHealth;

        public bool defeated = false;

        public Boss(int health = 100)
        {
            this.health = health;
            this.maxHealth = health;

            this.previousHealth = health;
            this.previousMaxHealth = health;
        }

        public virtual void Reset()
        {
            defeated = false;

            health = previousHealth;
            maxHealth = previousMaxHealth;
        }
    }
}
