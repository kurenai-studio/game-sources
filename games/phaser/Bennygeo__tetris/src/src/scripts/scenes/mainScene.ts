import { Game } from '../objects/Game';

export default class MainScene extends Phaser.Scene {
  _game: Game;

  constructor() {
    super({ key: 'MainScene' });
  }

  create() {
    this._game = new Game();
    this._game.create(this);
  }

  update() {
    // console.log("update");
    this._game.update();
  }
}
