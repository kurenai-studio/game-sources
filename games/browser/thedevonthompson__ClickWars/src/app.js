let http = require('http');
let fs = require('fs');
let url = require('url');
let path = require('path');

const port = 8080;

let server = http.createServer(function (req, res) {

    let uri = url.parse(req.url).pathname;
    let filename = path.join(process.cwd(), uri);

    /*
    // Remove comment for verbose uri logging.
    let array = uri.match(/[/](\w+)/g);
    if (array) {
        for (let i = 0; i < array.length; i++) {
            console.log(array[i]);
        }
    }
    */

    if (req.url === '/') {

        res.writeHead(200, { 'Content-Type' : 'text/html' });

        fs.createReadStream('index.html').pipe(res)
    }

    else if (uri.match(/[/](\w+)/)[1] === 'css') {
        fs.exists(filename, function(exists) {
            if (!exists) {
                console.log("Css doesn't exist: " + req.url);
                return404();
            } else {
                res.writeHead(200, { 'Content-Type' : 'text/css' });
                fs.createReadStream(filename).pipe(res);
            }
        });
    }

    else if (uri.match(/[/](\w+)/g)[0] === '/js' && uri.match(/[/](\w+)/g)[1] === '/client') {
        fs.exists(filename, function(exists) {
            if (!exists) {
                console.log("Client javascript doesn't exist: " + req.url);
                return404();
            } else {
                res.writeHead(200, { 'Content-Type' : 'text/javascript' });
                fs.createReadStream(filename).pipe(res);
            }
        });
    }

    // Currently only serves .pngs
    // TO DO: Write logic to detect file type and write http header with correct mime type.
    else if (uri.match(/[/](\w+)/)[1] === 'images') {
        fs.exists(filename, function(exists) {
            if (!exists) {
                console.log("Image doesn't exist: " + req.url);
                return404();
            } else {
                res.writeHead(200, { 'Content-Type' : 'image/png' });
                fs.createReadStream(filename).pipe(res);
            }
        });
    }

    else {
        console.log("Else reached, here is request url: " + req.url);
        return404(res);
    }

})

function return404(res) {
    res.writeHead(200, { 'Content-Type' : 'text/plain' });
    res.write('Error 404: Not Found');
    res.end();
}

// SOCKET.IO
let io = require('socket.io')(server);
let Center = require('./js/server/center.js');
let Client = require('./js/server/client.js');
let Enemy = require('./js/server/enemy.js');
let Engine = require('./js/server/engine.js');

io.on('connection', function(socket) {

    console.log('A user connected! ID: ' + socket.id);
    let client = new Client.create(socket.id);
    socket.emit('initView', Engine.Canvas, socket.id, Client.playerList, Client.gmId, Center);

    socket.on('playGame', function() {

        Client.moveToPlayerList(socket.id);
        Client.updateGm();
        socket.emit('initGame', Client.playerList, Client.gmId);
        Engine.Gm.updateBaseIncome();

        if (!Engine.serverIntervalId) {
            console.log("Engine interval started!");
            Engine.serverIntervalId = setInterval(function() {
                Enemy.move();
                io.emit('intervalUpdate', Center, Client.playerList, Enemy.list);
                io.sockets.connected[Client.gmId].emit('updateGmResources', Engine.Gm.resources, Engine.Gm.resourceCap, Engine.Gm.calcIncome());
                // if (Center.health <= 0) {
                //     clearInterval(Engine.serverIntervalId);
                //     io.emit('gameOver');
                // }
            }, Engine.serverIntervalSpeed);
        }

        if (!Engine.Gm.intervalId) {
            console.log("GM update interval started!");
            Engine.Gm.intervalId = setInterval(function() {
                Engine.Gm.resourceUpdate();
            }, Engine.Gm.intervalSpeed);
        }

        // Temporary enemy creation for testing purposes.
        if (!Engine.enemyTestingId) {
            console.log("Enemy testing interval started!");
            Engine.enemyTestingId = setInterval(function() {
                let enemy = new Enemy.createBasic();
            }, 3000);
        }
    });

    socket.on('clientMovement', function(x, y) {
        Client.playerList.map(function(client) {
            if (client.id === socket.id) {
                client.mouseX = x;
                client.mouseY = y;
            }
        });
    });

    socket.on('removeEnemy', function(id) {
        Enemy.removeById(id);
    });

    socket.on('createEnemy', function(type) {
        Enemy.createEnemy(type);
    });

    socket.on('hurtEnemy', function(id) {
        Enemy.hurtEnemy(id);
    });

    socket.on('setGmId', function() {
        console.log("Recieve command to change GM from ID: " + socket.id);
        Client.setGm(socket.id);
        io.emit('updateGm', Client.playerList, socket.id);
    });

    socket.on('disconnect', function() {
        console.log('A user disconnected! ID: ' + socket.id);
        let clientList = Client.findList(socket.id);
        Client.remove(socket.id, clientList);

        if ( Client.playerList.length <= 0 && !isNaN(Engine.serverIntervalId) ) {
            clearInterval(Engine.serverIntervalId);
            Engine.serverIntervalId = NaN;
        }

        Client.updateGm();

        if (clientList == "playerList" && Client.playerList.length > 0) {
            Engine.Gm.updateBaseIncome();
            io.emit('updateGm', Client.playerList, Client.gmId);
        }
    });
});

// Start server
server.listen(port, function(err) {
    if (err) {
        console.log('Error: ' + err);
    }
    console.log('Server listening on port: ' + port);
});