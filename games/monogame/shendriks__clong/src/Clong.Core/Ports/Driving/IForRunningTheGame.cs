using Clong.Core.Domain.Dto;

namespace Clong.Core.Ports.Driving;

public interface IForRunningTheGame
{
    public void Update(GameTime gameTime);
    public void Draw();
}