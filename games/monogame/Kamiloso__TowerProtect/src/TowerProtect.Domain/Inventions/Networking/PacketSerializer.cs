using AutoInterfaceAttributes;
using System.Text.Json;

namespace TowerProtect.Domain.Inventions.Networking;

[AutoInterface]
public class PacketSerializer : IPacketSerializer
{
    public string Serialize<T>(T packet) where T : struct, IPacket
    {
        return $"{T.Identifier}:{JsonSerializer.Serialize(packet)}";
    }

    public bool TryExtractPayload(string message, out int identifier, out string payload)
    {
        identifier = 0;
        payload = "";

        int splitIndex = message.IndexOf(':');
        if (splitIndex == -1) return false;

        if (!int.TryParse(message[..splitIndex], out identifier))
            return false;

        payload = message[(splitIndex + 1)..];
        return true;
    }

    public bool TryDeserialize<T>(string payload, out T packet) where T : struct, IPacket
    {
        try
        {
            packet = JsonSerializer.Deserialize<T>(payload);
            return true;
        }
        catch (JsonException)
        {
            packet = default;
            return false;
        }
    }
}
