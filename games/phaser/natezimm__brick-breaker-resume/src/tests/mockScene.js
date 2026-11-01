class MockGameObject {
  constructor(x = 0, y = 0, texture = null) {
    this.x = x;
    this.y = y;
    this.texture = texture;
    this.destroyed = false;
  }

  setOrigin() {
    return this;
  }

  setDepth() {
    return this;
  }

  setScrollFactor() {
    return this;
  }

  setDisplaySize(width, height) {
    this.width = width;
    this.height = height;
    this.displayWidth = width;
    this.displayHeight = height;
    return this;
  }

  setTexture(texture) {
    this.texture = texture;
    return this;
  }

  setPosition(x, y) {
    this.x = x;
    this.y = y;
    return this;
  }

  setBounce() {
    return this;
  }

  setCollideWorldBounds() {
    return this;
  }

  setImmovable() {
    return this;
  }

  destroy() {
    this.destroyed = true;
  }
}

class MockGraphics {
  constructor() {
    this.fillStyle = jest.fn();
    this.fillRect = jest.fn();
    this.beginPath = jest.fn();
    this.moveTo = jest.fn();
    this.lineTo = jest.fn();
    this.closePath = jest.fn();
    this.fillPath = jest.fn();
    this.lineStyle = jest.fn();
    this.strokePath = jest.fn();
    this.clear = jest.fn();
    this.fillCircle = jest.fn();
    this.fillRoundedRect = jest.fn();
  }

  destroy() {
    this.destroyed = true;
  }
}

class MockRectangle extends MockGameObject {
  constructor(x, y, width, height, color, alpha) {
    super(x, y);
    this.width = width;
    this.height = height;
    this.color = color;
    this.alpha = alpha;
    this.data = new Map();
    this.body = {
      setSize: jest.fn(),
      setCollideWorldBounds: jest.fn(),
    };
  }

  setData(key, value) {
    this.data.set(key, value);
    return this;
  }

  getData(key) {
    return this.data.get(key);
  }
}

class MockText extends MockGameObject {
  constructor(x, y, text, style) {
    super(x, y);
    this.text = text;
    this.style = style;
  }

  setText(text) {
    this.text = text;
    return this;
  }

  setResolution(resolution) {
    this.resolution = resolution;
    return this;
  }
}

class MockImage extends MockGameObject {
  constructor(x, y, texture) {
    super(x, y, texture);
  }
}

class MockPhysicsImage extends MockImage {
  constructor(x, y, texture) {
    super(x, y, texture);
    this.width = 100;
    this.height = 20;
    this.body = {
      velocity: { x: 0, y: 0 },
      onWorldBounds: false,
      setCollideWorldBounds: jest.fn(),
      setSize: jest.fn(),
    };
    this.body.gameObject = this;
  }

  setVelocity(x, y) {
    this.body.velocity = { x, y };
    return this;
  }

  setRotation() {
    return this;
  }
}

export function createMockScene() {
  const worldEvents = {};
  const world = {
    isPaused: false,
    on: jest.fn((event, cb) => {
      worldEvents[event] = cb;
    }),
    emit: (event, ...args) => {
      if (worldEvents[event]) worldEvents[event](...args);
    },
    setBounds: jest.fn(),
  };

  const staticGroup = {
    items: [],
    add: jest.fn((obj) => {
      staticGroup.items.push(obj);
      return obj;
    }),
    countActive: jest.fn(
      () => staticGroup.items.filter((item) => !item.destroyed).length
    ),
  };

  const colliders = [];

  const physicsAdd = {
    existing: jest.fn((obj) => {
      obj.body = obj.body || {
        setSize: jest.fn(),
        setCollideWorldBounds: jest.fn(),
      };
    }),
    image: jest.fn((x, y, texture) => new MockPhysicsImage(x, y, texture)),
    collider: jest.fn((a, b, cb) => {
      colliders.push(cb);
      return cb;
    }),
    staticGroup: jest.fn(() => staticGroup),
  };

  const add = {
    graphics: jest.fn(({ x, y }) => new MockGraphics(x, y)),
    rectangle: jest.fn(
      (x, y, width, height, color, alpha) =>
        new MockRectangle(x, y, width, height, color, alpha)
    ),
    text: jest.fn((x, y, text, style) => new MockText(x, y, text, style)),
    image: jest.fn((x, y, texture) => new MockImage(x, y, texture)),
  };

  const textures = {
    addCanvas: jest.fn(),
    exists: jest.fn(() => false),
    remove: jest.fn(),
  };

  const input = {
    events: {},
    on: jest.fn((event, cb) => {
      input.events[event] = cb;
    }),
    keyboard: {
      on: jest.fn((event, cb) => {
        input.events[event] = cb;
      }),
    },
  };

  const sound = { play: jest.fn(), mute: false };

  const loadEvents = {};
  const load = {
    audio: jest.fn(),
    once: jest.fn((event, cb) => {
      loadEvents[event] = cb;
    }),
    start: jest.fn(() => {
      if (loadEvents['complete']) {
        setTimeout(() => loadEvents['complete'](), 0);
      }
    }),
  };

  const scene = {
    add,
    load,
    physics: { add: physicsAdd, world },
    input,
    sound,
    textures,
    scale: { resize: jest.fn() },
    scene: { scenes: [] },
    colliders,
  };

  return scene;
}

export { MockGraphics, MockRectangle, MockText, MockImage, MockPhysicsImage };
