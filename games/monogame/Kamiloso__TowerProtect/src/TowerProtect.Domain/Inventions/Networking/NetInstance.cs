using AutoInterfaceAttributes;
using System;
using System.Security.Cryptography;

namespace TowerProtect.Domain.Inventions.Networking;

[AutoInterface]
internal class NetInstance : INetInstance
{
    public long Id { get; }

    public NetInstance()
    {
        do
        {
            byte[] buffer = RandomNumberGenerator.GetBytes(8);
            Id = BitConverter.ToInt64(buffer, 0);
        }
        while (Id == 0);
    }
}
