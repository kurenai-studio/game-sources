import { Box3, BoxGeometry, Mesh, MeshBasicMaterial, Vector3 } from "three";

let index = 1;

const projectileController = {
    projectiles: [],
    projecttileGeometry: new BoxGeometry(0.1, 0.1, 0.1),
    playerPosition: new Vector3(0, 0, 0),
    projectileSpeed: 0.1,
    scene: undefined,
    initProjectileController(playerPosition, scene) {
        this.playerPosition = playerPosition
        this.scene = scene
    },
    spawnProjectile(enemy) {
        const projectile = new Mesh(this.projecttileGeometry, new MeshBasicMaterial({ color: 0xffffff }));
        projectile.position.copy(this.playerPosition)
        projectile.position.setZ(projectile.position.z + 0.7)
        this.scene.add(projectile);
        projectile.lookAt(enemy.enemyMesh.position)
        const boudingBox = new Box3()
        boudingBox.setFromObject(projectile)
        this.projectiles.push({
            projectileMesh: projectile,
            projectileBoundingBox: boudingBox,
            name: "projectile " + index,
            target: enemy
        })
        index++
    },
    moveProjectiles() {
        this.projectiles.map((projectile) => {
            projectile.projectileMesh.translateZ(this.projectileSpeed);
            projectile.projectileBoundingBox.setFromObject(projectile.projectileMesh)
            this.checkCollision(projectile)
        })
    },
    checkCollision(projectile) {
        if (projectile.target.enemyBoundingSphere.intersectsBox(projectile.projectileBoundingBox)) {
            this.scene.remove(projectile.projectileMesh)
            this.projectiles = this.projectiles.filter(item => item.name != projectile.name);
            projectile.target.health--
            if (projectile.target.health <= 0) {
                this.event = new CustomEvent('enemy-destroyed', { detail: projectile.target.name });
                document.dispatchEvent(this.event);
            }
        }
    }
}

export { projectileController }