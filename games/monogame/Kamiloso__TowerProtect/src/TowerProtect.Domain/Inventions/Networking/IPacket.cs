using TowerProtect.Domain.Inventions.Interfaces;

namespace TowerProtect.Domain.Inventions.Networking;

public interface IPacket : IHasValidation
{
    static abstract int Identifier { get; }

    // Multiplayer is delayed, so we just ignore validation for now.
    bool IHasValidation.IsValid() => true;
}
