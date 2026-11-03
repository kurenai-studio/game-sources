import { Box3, BoxGeometry, Mesh, MeshNormalMaterial, Vector3 } from 'three'

const playerController = {
    playerPosition: new Vector3(0, 0, 0),
    playerBoundingBox: new Box3(),
    player: undefined,
    instanciatePlayer(scene) {
        this.player = new Mesh(new BoxGeometry(.1, 0.1, 0.7), new MeshNormalMaterial({ color: 0xffffff }));
        this.player.position.copy(this.playerPosition)
        this.player.rotateX(Math.PI / 2)
        scene.add(this.player)
        this.playerBoundingBox.setFromObject(this.player)
    }
}

export { playerController }