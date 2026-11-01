const createCanvasContext = () => {
  const gradientStub = () => ({
    addColorStop: jest.fn(),
  });

  return {
    fillStyle: '',
    beginPath: jest.fn(),
    roundRect: jest.fn(),
    arc: jest.fn(),
    fill: jest.fn(),
    createRadialGradient: jest.fn(gradientStub),
    createLinearGradient: jest.fn(gradientStub),
    fillRect: jest.fn(),
    strokeStyle: '',
    lineWidth: 0,
    stroke: jest.fn(),
    strokeRect: jest.fn(),
    moveTo: jest.fn(),
    lineTo: jest.fn(),
    closePath: jest.fn(),
    fillPath: jest.fn(),
  };
};

const { TextDecoder, TextEncoder } = require('util');

global.TextDecoder = global.TextDecoder || TextDecoder;
global.TextEncoder = global.TextEncoder || TextEncoder;

HTMLCanvasElement.prototype.getContext = jest.fn(() => createCanvasContext());

global.Phaser = {
  AUTO: 'AUTO',
  Math: {
    Clamp: (value, min, max) => Math.min(Math.max(value, min), max),
  },
  Game: jest.fn(function Game(config) {
    this.config = config;
    this.scene = { scenes: [] };
    this.physics = { world: { setBounds: jest.fn() } };
  }),
};

jest.mock('phaser', () => global.Phaser);

if (typeof File === 'undefined') {
  global.File = class File extends Blob {
    constructor(parts, name, options) {
      super(parts, options);
      this.name = name;
    }
  };
}
