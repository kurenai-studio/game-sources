using System;
using System.Collections.Concurrent;
using System.Diagnostics.CodeAnalysis;
using System.Threading;

public class TaskProcessor
{
    private readonly BlockingCollection<Action> _taskQueue = new();
    private readonly Thread[] _workerThreads;
    private bool _isRunning = true;
    
    public TaskProcessor(int? numberOfThreads = null)
    {
        numberOfThreads ??= Environment.ProcessorCount;
        _workerThreads = new Thread[(int)numberOfThreads];

        for (int i = 0; i < numberOfThreads; i++)
        {
            _workerThreads[i] = new Thread(ProcessTasks)
            {
                IsBackground = true
            };
            _workerThreads[i].Start();
        }
    }

    public void EnqueueTask(Action task)
    {
        _taskQueue.Add(task);
    }

    public void Stop()
    {
        _isRunning = false;
        _taskQueue.CompleteAdding();

        while (_taskQueue.TryTake(out _)) { }

        foreach (Thread thread in _workerThreads)
        {
            thread.Join(); // Wait for all threads to finish
        }
    }

    private void ProcessTasks()
    {
        while (_isRunning || !_taskQueue.IsCompleted)
        {
            try
            {
                Action task = _taskQueue.Take(); // Blocks until a task is available
                task.Invoke();
            }
            catch (InvalidOperationException)
            {
                // Handle case where queue is empty and CompleteAdding is called
                break;
            }
        }
    }
}
