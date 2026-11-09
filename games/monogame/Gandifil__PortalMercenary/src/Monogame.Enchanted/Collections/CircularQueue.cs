using System.Dynamic;

namespace Monogame.Enchanted.Collections;

public class CircularQueue<T> where T: struct
{
    public readonly T[] Data;
    private readonly int _mask;
    
    public int Head { get; private set; }

    public CircularQueue(int capacity)
    {
        // Enforce power of 2 for fast bitwise indexing
        if ((capacity & (capacity - 1)) != 0)
            throw new ArgumentException("Capacity must be a power of 2.");

        Data = new T[capacity];
        _mask = capacity - 1;
        Head = 0;
    }

    public T this[int index]
    {
        get => Data[GetIndex(index)];
        set => Data[GetIndex(index)] = value;
    }

    private int GetIndex(int index) => (Head + index) & _mask;

    public bool Enqueue(T item)
    {
        Data[Head] = item;
        Head = (Head + 1) & _mask;
        return true;
    }
}
