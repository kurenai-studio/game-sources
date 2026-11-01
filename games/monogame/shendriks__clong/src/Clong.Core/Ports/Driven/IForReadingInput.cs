using Clong.Core.Domain.Input;

namespace Clong.Core.Ports.Driven;

public interface IForReadingInput
{
    public InputState ReadInput();
}