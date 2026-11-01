import StartGame from "./game/main";

document.addEventListener("DOMContentLoaded", async () => {
  const params = new URLSearchParams(window.location.search);

  const playerName = params.get("name") || "Guest-Player";

  StartGame("game-container", { name: playerName });
});
