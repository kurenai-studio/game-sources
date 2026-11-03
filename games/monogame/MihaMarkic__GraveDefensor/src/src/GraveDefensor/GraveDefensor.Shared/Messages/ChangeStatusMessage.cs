namespace GraveDefensor.Shared.Messages
{
    public readonly struct ChangeStatusMessage
    {
        public int Amount { get; }
        public int Health { get; }
        public ChangeStatusMessage(int amount, int health)
        {
            Amount = amount;
            Health = health;
        }
    }
}
