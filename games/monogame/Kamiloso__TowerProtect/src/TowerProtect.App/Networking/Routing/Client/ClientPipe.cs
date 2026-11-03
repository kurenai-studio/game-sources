using AutoInterfaceAttributes;
using System;
using System.Collections.Generic;
using TowerProtect.App.Networking.Routing.Client;

namespace TowerProtect.App.Networking.Client;

partial interface IClientPipe : IClientFrontPipe, IClientBackPipe;

[AutoInterface]
internal class ClientPipe : IClientPipe
{
    private readonly Queue<string> _buffer = [];
    private bool _isDead;

    public event Action<string>? OnSendEvent;

    public void Send(string message) => OnSendEvent?.Invoke(message);
    public void PushMessage(string message) => _buffer.Enqueue(message);
    public bool TryDequeue(out string message) => _buffer.TryDequeue(out message!);

    public void MarkAsDead() => _isDead = true;
    public bool IsDead() => _isDead;
}
