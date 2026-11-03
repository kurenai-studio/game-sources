import { Box3, BoxGeometry, Mesh, MeshNormalMaterial, OrthographicCamera, Scene, Vector3, WebGLRenderer } from 'three';
import { TWEEN } from 'three/examples/jsm/libs/tween.module.min'
import { enemyController } from './enemyController';
import { playerController } from './playerController';
import { projectileController } from './projectileController';
import { wordController } from './wordController';

var camera,
    scene,
    element = document.getElementById('demo'),
    waveMessage = document.getElementById('waveMessage'),
    renderer,
    width = window.innerWidth,
    height = window.innerHeight,
    ratio = width / height,
    waveEnemyCount = 2,
    frustumSize = 10;

function initScene() {
    camera = new OrthographicCamera(
        frustumSize * ratio / - 2,
        frustumSize * ratio / 2,
        frustumSize / 2,
        frustumSize / - 2,
        1,
        1000);
    scene = new Scene();
    camera.position.set(0, 0, 2)

    renderer = new WebGLRenderer();
    renderer.setSize(width, height);
    element.appendChild(renderer.domElement);

    playerController.playerPosition = new Vector3(0, (frustumSize / - 2) + 0.75, 0)
    // playerController.loadFbxModel(scene, "lowpoly_turrent.fbx")
    playerController.instanciatePlayer(scene)

    enemyController.initEnemyController(width, height, frustumSize, playerController.playerPosition, playerController.playerBoundingBox, camera, scene)
    projectileController.initProjectileController(playerController.playerPosition, scene)

    wordController.initWordsList()
    nextWave()

    window.addEventListener('resize', onResize, false);

    document.body.onkeyup = function (e) {
        const currentEnemy = enemyController.pickEnemy(e.key)
        if (currentEnemy && e.key == currentEnemy.word[0]) {
            currentEnemy.word.shift()
            if (currentEnemy.word.length > 0) {
                currentEnemy.wordElement.innerHTML = currentEnemy.word.join('')
            } else {
                enemyController.currentEnemy = undefined
                element.removeChild(currentEnemy.wordElement)
            }
            playerController.player.lookAt(currentEnemy.enemyMesh.position)
            // let dy = currentEnemy.enemyMesh.position.y - playerController.player.position.y
            // let dx = currentEnemy.enemyMesh.position.x - playerController.player.position.x
            // let theta = angle(playerController.player.position.z, playerController.player.position.y, currentEnemy.enemyMesh.position.x, currentEnemy.enemyMesh.position.y)
            // playerController.player.setRotationFromAxisAngle(new Vector3(0, 0, -1), theta)
            projectileController.spawnProjectile(currentEnemy)
        }
        if (e.key == " " || e.code == "Space") {
            projectileController.spawnProjectile(currentEnemy)
        }
    }
    document.addEventListener('enemy-destroyed', (e) => nextWave(), false);
    document.addEventListener('game-over', (e) => {
        waveMessage.classList.add("is-active")
        waveMessage.innerHTML = "Game Over!"
        enemyController.gameOver()
    }, false);

    render();
}

function nextWave() {
    if (enemyController.enemies.length <= 0) {
        waveMessage.classList.add("is-active")
        setTimeout(() => {
            for (let i = 0; i < waveEnemyCount; i++) {
                enemyController.spawnEnemy(wordController.createEnemyWordElement())
            }
            if (waveEnemyCount < 6) waveEnemyCount++
            waveMessage.classList.remove("is-active")
        }, 1500)
    }
}

function angle(cx, cy, ex, ey) {
    var dy = ey - cy;
    var dx = ex - cx;
    var theta = Math.atan2(dy, dx); // range (-PI, PI]
    theta *= 180 / Math.PI; // rads to degs, range (-180, 180]
    if (theta < 0) theta = 360 + theta; // range [0, 360)
    return theta;
}

function onResize() {
    width = window.innerWidth
    height = window.innerHeight,
        renderer.setSize(width, height);
    camera.aspect = width / height
    camera.updateProjectionMatrix()
}

function render(time) {
    TWEEN.update(time);
    requestAnimationFrame(render);
    renderer.render(scene, camera);
    projectileController.moveProjectiles()
}

initScene()