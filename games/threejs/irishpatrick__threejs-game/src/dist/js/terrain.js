let fs = require("fs");
let path = require("path");
let THREE = require("three");
let noise = require("./lib/perlin.js");

let assetpath = path.join(__dirname, "..", "assets");

function normalize(value, max) {
    return value / max;
}

class Terrain {
    constructor(fn) {
        let geo = new THREE.PlaneGeometry(100, 100, 128, 128);
        let mat = new THREE.MeshPhongMaterial({color: 0x00dd00, side: THREE.DoubleSide});
        this.mesh = new THREE.Mesh(geo, mat);
        this.mesh.rotation.x = -Math.PI / 2;

        let ref = this;
        fs.readFile(path.join(assetpath, fn), function(err, data) {
            if (!err) {
                console.log(JSON.parse(data));
                ref.process(JSON.parse(data));

            } else {
                console.log(err);
            }
        });
    }

    getMesh() {
        return this.mesh;
    }

    process(json) {
        //console.log(json);
        /*for (let feature of json.features) {
            //console.log(feature);
            for (let vector of this.mesh.geometry.vertices) {
                let center = new THREE.Vector3(feature.location[0]-50, feature.location[1]-50, 0);
                let dist = center.distanceTo(vector) / 3;
                let max = Math.sqrt(2 * Math.pow(100, 2));
                let n = normalize(dist, max);
                //console.log(vector);
                //console.log("dist: " + dist + ", max: " + max + ", n: " + n);

                if (n > 0) {
                    //console.log("apply amp");
                    //console.log(feature.amp * n)
                    vector.z += feature.amp * Math.pow(n,3);
                } else {
                    //console.log("fail");
                }
            }
        }
        this.mesh.geometry.verticesNeedUpdate = true;*/
    }
}

module.exports = Terrain;
