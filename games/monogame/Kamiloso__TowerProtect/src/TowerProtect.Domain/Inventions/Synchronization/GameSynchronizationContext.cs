using System;
using System.Collections.Concurrent;
using System.Threading;

namespace TowerProtect.Domain.Inventions.Synchronization;

public class GameSynchronizationContext : SynchronizationContext
{
    private readonly ConcurrentQueue<WorkItem> _workItems = [];

    public override void Post(SendOrPostCallback d, object? state)
        => _workItems.Enqueue(new(d, state));

    public override void Send(SendOrPostCallback d, object? state)
        => throw new NotSupportedException("Send is not supported in this context.");

    public void ProcessPending()
    {
        while (_workItems.TryDequeue(out var item))
        {
            item.Callback(item.State);
        }
    }

    private readonly record struct WorkItem(
        SendOrPostCallback Callback,
        object? State);
}
