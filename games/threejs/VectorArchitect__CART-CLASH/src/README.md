# CART CLASH

A browser-based, real-time 1v1 kart combat game prototype built with Three.js, Node.js, Express, and Socket.IO.

> **Status:** Early prototype (v0.1.1-based GitHub upload). Gameplay and multiplayer behavior are still being developed and tested.

## Current concept

Two players enter the same arena from separate devices, drive their carts, aim manually, and fire projectiles. Matches end when a player's health reaches zero or when the match timer expires.

## Technology

- **Three.js** — 3D rendering and third-person camera
- **Node.js + Express** — application server
- **Socket.IO** — real-time multiplayer communication
- **JavaScript** — client and server implementation

## Features in this prototype

- Browser-based game; no account or signup flow
- Room creation and room-code joining
- Two-player multiplayer session
- Third-person camera concept
- Keyboard driving controls
- Mouse aiming and shooting
- Health display and match timer
- Touch-control interface groundwork

Features and controls may change as the prototype evolves. This repository should not be considered a production-ready game.

## Requirements

- Node.js 18 or later
- npm
- A modern desktop or mobile browser with WebGL support

## Run locally

1. Clone the repository:

   ```bash
   git clone https://github.com/VectorArchitect/CART-CLASH.git
   cd CART-CLASH
   ```

2. Install dependencies:

   ```bash
   npm install
   ```

3. Start the server:

   ```bash
   npm start
   ```

4. Open [http://localhost:3000](http://localhost:3000).

## Multiplayer testing

For a basic local test, open the game in two browser windows and create/join a room using the room code.

To test with another device on the same Wi-Fi network, find the host computer's local IP address and open:

```text
http://YOUR_LOCAL_IP:3000
```

Both devices must be able to reach the host computer, and the host firewall must allow the server port.

For play across different networks, deploy the Node.js server to a publicly reachable host and use HTTPS/WSS in production. A local `localhost` server is not accessible to remote players.

## Controls

### Keyboard and mouse

- **W / A / S / D** or **Arrow keys** — drive
- **Mouse** — aim
- **Hold left mouse button** — fire

Exact input behavior may vary by current prototype build.

### Touch devices

The interface includes touch-control support. Touch controls are under active development and should be tested on the target phone/tablet browsers.

## Roadmap

- [ ] Stabilize arena geometry and third-person camera
- [ ] Refine acceleration, steering, collisions, and driving feel
- [ ] Verify two-device multiplayer synchronization
- [ ] Improve mobile joystick and multitouch controls
- [ ] Add coins and XP tokens
- [ ] Add health pickups and boosters
- [ ] Add additional weapons, including rocket launchers
- [ ] Add deployment, reconnection, and match reliability improvements

## Project structure

```text
CART-CLASH/
├── client/
│   ├── game.js
│   ├── index.html
│   └── style.css
├── server/
│   └── index.js
├── .gitignore
├── package.json
└── README.md
```

## Contributions and feedback

Bug reports, suggestions, and improvement ideas are welcome through GitHub Issues.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
