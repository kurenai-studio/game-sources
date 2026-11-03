let THREE = require("three");

function rad(deg) {
    return deg * (Math.PI / 180);
}

class FirstPersonCamera {
    constructor(camera) {
        this.yaw = new THREE.Object3D();
        this.pitch = new THREE.Object3D();

        this.pitch.add(camera);
        this.yaw.add(this.pitch);

        this.enabled = false;

        this.sensitivity = 0.012;

        let scope = this;
        this.onMouseMove = function (e) {
            if (scope.enabled === false) {
                return;
            }

            var mx = e.movementX || e.mozMovementX || e.webkitMovementX || 0;
            var my = e.movementY || e.mozMovementY || e.webkitMovementY || 0;

            scope.yaw.rotation.y -= rad(mx * scope.sensitivity);
            scope.pitch.rotation.x -= rad(my * scope.sensitivity);

            scope.pitch.rotation.x = Math.max(
                -Math.PI/2,
                Math.min(Math.PI/2, scope.pitch.rotation.x));
        };

        document.addEventListener("mousemove", this.onMouseMove, false);
    }

    initPointerLock() {

    }

    dispose() {
        document.removeEventListener("mousemove", this.onMouseMove, false);
    }

    getObject() {
        return this.yaw;
    }
}

module.exports = FirstPersonCamera;
