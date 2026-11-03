using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;

namespace MonoGameLibrary.Components.Infrastructure
{
    public readonly struct ComponentTypeMask(ulong bitsA, ulong bitsB)
    {
        readonly ulong BitsA = bitsA;
        readonly ulong BitsB = bitsB;

        public static readonly ComponentTypeMask Empty = new();

        public bool ContainsAll(ComponentTypeMask other)
        {
            return (BitsA & other.BitsA) == other.BitsA &&
                (BitsB & other.BitsB) == other.BitsB;
        }

        public bool ContainsAny(ComponentTypeMask other)
        {
            return (BitsA & other.BitsA) != 0 ||
                (BitsB & other.BitsB) != 0;
        }

        public bool ContainsType(Type type)
        {
            return ContainsAny(FromType(type));
        }

        public ComponentTypeMask With(ComponentTypeMask other)
        {
            return new ComponentTypeMask(BitsA | other.BitsA,
                BitsB | other.BitsB);
        }

        internal IEnumerable<Type> GetTypesFromMask()
        {
            foreach (var pair in ComponentTypeRegistry.GetRegisteredTypesAndIds())
            {
                if (pair.Value < 64)
                {
                    if ((BitsA & (1UL << pair.Value)) != 0)
                    {
                        yield return pair.Key;
                    }
                }
                else
                {
                    if ((BitsB & (1UL << pair.Value)) != 0)
                    {
                        yield return pair.Key;
                    }
                }
            }
        }

        public override bool Equals([NotNullWhen(true)] object? obj)
        {
            if (obj is ComponentTypeMask other)
            {
                return BitsA == other.BitsA &&
                    BitsB == other.BitsB;
            }
            return false;
        }

        public static bool operator ==(ComponentTypeMask left, ComponentTypeMask right)
            => left.Equals(right);

        public static bool operator !=(ComponentTypeMask left, ComponentTypeMask right)
            => !left.Equals(right);

        public override int GetHashCode()
            => HashCode.Combine(BitsA, BitsB);

        public static ComponentTypeMask FromTypes(params Type[] componentTypes)
        {
            if(componentTypes.Length == 0)
            {
                return Empty;
            }
            var mask = FromType(componentTypes[0]);
            for (int index = 1; index < componentTypes.Length; index++)
            {
                mask = mask.With(FromType(componentTypes[index]));
            }
            return mask;
        }

        public static ComponentTypeMask FromType(Type componentType)
        {
            return FromTypeId(ComponentTypeRegistry.GetId(componentType));
        }

        public static ComponentTypeMask FromTypeId(int componentTypeId)
        {
            if (componentTypeId < 0 || componentTypeId >= 128)
            {
                throw new ArgumentOutOfRangeException(nameof(componentTypeId), $"{ nameof(componentTypeId) } must be within the range 0 < x < 128");
            }
            ulong newBitsA = 0;
            ulong newBitsB = 0;
            if(componentTypeId < 64)
            {
                newBitsA = 1UL << componentTypeId;
            } 
            else
            {
                newBitsB = 1UL << (componentTypeId - 64);
            }
            return new ComponentTypeMask(newBitsA, newBitsB);
        }

        public override string ToString()
        {
            return $"<{string.Join(", ", GetTypesFromMask().Select(type => type.Name))}>";
        }
    }
}
