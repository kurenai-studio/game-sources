class GameError extends Error {
  constructor(message: string) {
    super(message);
    Error.captureStackTrace(this, GameError);
  }
}

export default GameError;
