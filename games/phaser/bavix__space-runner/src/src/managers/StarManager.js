// Star Manager - Optimized starfield system
import { getColor } from '../utils/colorHelpers.js';
import { COLOR_PATHS } from '../constants/colorPaths.js';

export class StarManager {
  constructor(scene, themeManager) {
    this.scene = scene;
    this.themeManager = themeManager;
    this.stars = [];
    this.starsGraphics = null;
    this.lastStarColor = null;
    this.lastStarUpdate = 0;
    this.starUpdateInterval = 16;
    this.starCount = 100; // Increased star count for better visibility
  }

  initialize(gameWidth, gameHeight) {
    this.gameWidth = gameWidth;
    this.gameHeight = gameHeight;
    this.initStars();
  }

  initStars() {
    if (this.starsGraphics) {
      this.starsGraphics.destroy();
    }
    
    this.starsGraphics = this.scene.add.graphics();
    this.starsGraphics.setDepth(-1); // Behind everything
    
    // Use stars color or fallback to text color
    const starColor = getColor(this.themeManager, COLOR_PATHS.STARS) || getColor(this.themeManager, COLOR_PATHS.TEXT);
    this.lastStarColor = starColor;
    
    this.stars = [];
    for (let i = 0; i < this.starCount; i++) {
      this.stars.push({
        x: Math.random() * this.gameWidth,
        y: Math.random() * this.gameHeight,
        speed: 0.5 + Math.random() * 1.5,
        brightness: 0.3 + Math.random() * 0.7
      });
    }
    
    // Draw initial stars
    if (starColor && this.starsGraphics) {
      this.starsGraphics.clear();
      for (let i = 0; i < this.stars.length; i++) {
        const star = this.stars[i];
        this.starsGraphics.setAlpha(star.brightness);
        this.starsGraphics.fillStyle(starColor);
        this.starsGraphics.fillRect(star.x, star.y, 1, 1);
      }
      this.starsGraphics.setAlpha(1);
    }
  }

  update(hyperspeedMultiplier, time) {
    // Use text color for stars if stars color is not defined
    const starColor = getColor(this.themeManager, COLOR_PATHS.STARS) || getColor(this.themeManager, COLOR_PATHS.TEXT);
    
    // Reinitialize if color changed
    if (starColor !== this.lastStarColor) {
      this.initStars();
      return;
    }
    
    const shouldUpdate = (time - this.lastStarUpdate) >= this.starUpdateInterval;
    
    if (!shouldUpdate) {
      // Still update positions without redrawing
      const speedMultiplier = hyperspeedMultiplier;
      const starsLength = this.stars.length;
      for (let i = 0; i < starsLength; i++) {
        const star = this.stars[i];
        star.x -= star.speed * speedMultiplier;
        if (star.x < 0) {
          star.x = this.gameWidth;
          star.y = Math.random() * this.gameHeight;
        }
      }
      return;
    }
    
    this.lastStarUpdate = time;
    this.starsGraphics.clear();
    
    const speedMultiplier = hyperspeedMultiplier;
    const starsLength = this.stars.length;
    
    for (let i = 0; i < starsLength; i++) {
      const star = this.stars[i];
      star.x -= star.speed * speedMultiplier;
      
      if (star.x < 0) {
        star.x = this.gameWidth;
        star.y = Math.random() * this.gameHeight;
      }
      
      if (star.x >= 0 && star.x <= this.gameWidth) {
        this.starsGraphics.setAlpha(star.brightness);
        this.starsGraphics.fillStyle(starColor);
        this.starsGraphics.fillRect(star.x, star.y, 1, 1);
      }
    }
    
    this.starsGraphics.setAlpha(1);
  }

  clear() {
    if (this.starsGraphics) {
      this.starsGraphics.destroy();
      this.starsGraphics = null;
    }
    this.stars = [];
  }
}


