let THREE = require("three");

class Tree {
    constructor(size) {
        let trunk_radius = (size / 2) / (2 * Math.PI);
        let trunk_geo = new THREE.CylinderGeometry(
            trunk_radius, trunk_radius, size, 32);
        let trunk_mat = new THREE.MeshPhongMaterial({color: 0x593200});
        this.trunk = new THREE.Mesh(trunk_geo, trunk_mat);

        let top_radius = (size * 3) / (2 * Math.PI);
        let top_geo = new THREE.SphereGeometry(top_radius, 32, 32);
        let top_mat = new THREE.MeshPhongMaterial({color: 0x00841c});
        this.top = new THREE.Mesh(top_geo, top_mat);

        this.obj = new THREE.Object3D();
        this.obj.add(this.trunk);
        this.obj.add(this.top);

        this.trunk.position.y = size / 2;
        this.top.position.y = size + (top_radius * 0.75);

        this.obj.position.y = size/2;
    }

    getObject() {
        return this.obj;
    }
}

module.exports = Tree;
