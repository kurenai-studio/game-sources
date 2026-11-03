"use client";

import dynamic from "next/dynamic";

const GameClient = dynamic(() => import("./GameClient"), {
  ssr: false,
  loading: () => <div className="center-screen">Loading Keris...</div>,
});

export default function GameLoader() {
  return <GameClient />;
}
