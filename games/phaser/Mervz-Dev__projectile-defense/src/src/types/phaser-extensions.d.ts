import { ResponsiveDimensionsPlugin } from "../game/plugins/responsive-dimensions-plugin";

declare global {
  namespace Phaser {
    interface Scene {
      responsive: ResponsiveDimensionsPlugin;
    }
  }
}
