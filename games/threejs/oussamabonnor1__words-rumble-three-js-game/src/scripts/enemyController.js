import { Mesh, MeshBasicMaterial, Sphere, SphereGeometry, Vector3 } from "three";
import { TWEEN } from 'three/examples/jsm/libs/tween.module.min'
let index = 1
const enemyController = {
    enemies: [],
    enemyGeometry: new SphereGeometry(0.1),
    enemyTravelTime: 3000,
    currentEnemy: undefined,
    frustumSize: 50,
    width: 0,
    height: 0,
    playerPosition: new Vector3(0, 0, 0),
    playerBoundingBox: undefined,
    camera: undefined,
    scene: undefined,
    canvas: document.getElementById('demo'),
    initEnemyController(width, height, frustumSize, playerPosition, playerBoundingBox, camera, scene) {
        this.frustumSize = frustumSize
        this.width = width
        this.height = height
        this.playerPosition = playerPosition
        this.playerBoundingBox = playerBoundingBox
        this.camera = camera
        this.scene = scene
        document.addEventListener('enemy-destroyed', (e) => this.enemyDestroyed(e), false);
    },
    spawnEnemy(wordElement) {
        const enemy = new Mesh(this.enemyGeometry, new MeshBasicMaterial({ color: Math.random() * 0xffffff }));
        enemy.position.copy(new Vector3((Math.random() - 0.5) * 10, (this.frustumSize / 2) - (Math.random() * 3), 0)) //random X between -5 & 5
        this.scene.add(enemy);
        const boundingSphere = new Sphere(enemy.position, 0.1)
        this.enemies.push({
            enemyMesh: enemy,
            enemyBoundingSphere: boundingSphere,
            name: "enemy " + index,
            ...wordElement
        })
        this.moveEnemy(this.enemies[this.enemies.length - 1]);
        index++
    },
    moveEnemy(enemy) {
        new TWEEN.Tween(enemy.enemyMesh.position)
            .to(this.playerPosition, this.enemyTravelTime * enemy.health)
            .onUpdate((position) => {
                const projectedPostion = position.clone().project(this.camera)
                if (enemy.wordElement) {
                    enemy.wordElement.style.top = ((projectedPostion.y * -1 + 1) * this.height / 2) + 'px'
                    enemy.wordElement.style.left = ((projectedPostion.x + 1) * this.width / 2) + 'px'
                }
                enemy.enemyBoundingSphere.center.copy(position)
                this.checkCollision()
            })
            .start()
    },
    checkCollision() {
        this.enemies.map((enemy) => {
            if (enemy.enemyBoundingSphere.intersectsBox(this.playerBoundingBox)) {
                document.dispatchEvent(new CustomEvent('game-over'));
            }
        })
    },
    enemyDestroyed(e) {
        const enemyIndex = this.enemies.findIndex((enemy) => enemy.name == e.detail)
        if (enemyIndex >= 0) {
            this.scene.remove(this.enemies[enemyIndex].enemyMesh)
            this.enemies.splice(enemyIndex, 1);
        }
    },
    pickEnemy(letter) {
        if (!this.currentEnemy) {
            for (let i = 0; i < this.enemies.length; i++) {
                if (this.enemies[i].word[0] == letter) {
                    this.enemies[i].wordElement.classList.add("currentEnemy")
                    this.currentEnemy = this.enemies[i]
                    break
                }
            }
        }
        return this.currentEnemy
    },
    gameOver() {
        this.enemies.map((enemy) => {
            this.scene.remove(enemy.enemyMesh)
            this.canvas.removeChild(enemy.wordElement)
        })
        this.enemies = []
    }
}

export { enemyController }