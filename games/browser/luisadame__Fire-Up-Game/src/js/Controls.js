import keydown from './Keydown';
import Hero from './Hero';

function handleControls(e) {
    if (e.keyCode === 37) keydown.left = e.type === "keydown";
    if (e.keyCode === 39) keydown.right = e.type === "keydown";
    if (e instanceof TouchEvent) {
        if (e.type === "touchstart") {
            let touch = e.touches[0].clientX;
            if (touch < Hero.x + (Hero.w / 2)) keydown.left = true;
            if (touch > Hero.x + (Hero.w / 2)) keydown.right = true;
        } else {
            keydown.left = false;
            keydown.right = false;
        }
    }
}

export function addEventListeners() {
    window.addEventListener('keydown', handleControls);
    window.addEventListener('keyup', handleControls);
    window.addEventListener('touchstart', handleControls);
    window.addEventListener('touchend', handleControls);
}
