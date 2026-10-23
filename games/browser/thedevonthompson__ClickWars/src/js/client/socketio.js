let SocketIO = {

    socket: io(),
    ownClientId: null,
    gmClientId: null,
    
    clientList: [],
    enemyList: [],
    Center: {},

    init: function() {

        SocketIO.socket.on('initView', function(canvas, id, clients, gmId, center) {

            SocketIO.ownClientId = id;
            SocketIO.clientList = clients;
            SocketIO.Center = center;

            if (clients.length > 0) {
                SocketIO.gmClientId = gmId;
            }

            SocketIO.loadCanvas(canvas);
            Canvas.init();

            let startBtn = Canvas.createButton('startBtn', 'cmdBtn', 'Join Game',
            function() {
                SocketIO.socket.emit('playGame');
            });

            document.getElementsByTagName('main')[0].appendChild(startBtn);
        });

        SocketIO.socket.on('initGame', function(clients, gmId) {

            document.getElementsByTagName('main')[0].removeChild( document.getElementById('startBtn') );

            SocketIO.clientList = clients;
            SocketIO.gmClientId = gmId;

            if (SocketIO.isGm()) {
                Gm.init();
            } else {
                Player.init();
            }

            // TO DO: Figure out how to remove initializeGame and initView listener?
        });

        SocketIO.socket.on('intervalUpdate', function(center, clients, enemys) {
            SocketIO.Center = center;
            SocketIO.clientList = clients;
            SocketIO.enemyList = enemys;
        });

        SocketIO.socket.on('updateGm', function(clients, gmId) {
            let wasGm = SocketIO.isGm()

            SocketIO.clientList = clients;
            SocketIO.gmClientId = gmId;

            if (!wasGm && SocketIO.isGm()) {
                Player.deInit();
                Gm.init();
            }
            else if (wasGm && !SocketIO.isGm()) {
                Gm.deInit();
                Player.init();
            }
        });

        SocketIO.socket.on('updateGmResources', function(resources, resourceCap, income) {
            Gm.resources = resources;
            Gm.resourceCap = resourceCap;
            Gm.income = income;
        });

        SocketIO.socket.on('gameOver', function() {
            Canvas.gameOver = true;
        });

    },

    loadCanvas: function(canvas) {
        Canvas.width = canvas.width;
        Canvas.height = canvas.height;
        Canvas.id = canvas.id;
        Canvas.containerId = canvas.containerId;
        Canvas.drawIntervalSpeed = canvas.drawIntervalSpeed;
        Canvas.colorList = canvas.colorList;
    },

    emitMovement: function(x, y) {
        SocketIO.socket.emit('clientMovement', x, y);
    },

    removeEnemy: function(id) {
        SocketIO.socket.emit('removeEnemy', id);
    },

    isGm: function() {
        if (SocketIO.ownClientId === SocketIO.gmClientId) {
            return true;
        }
        return false;
    }

    /*
    This function dynamically loads another javascript file from the server.
    I decided to approach it problem a different way, but this was interesting.
    loadScript: function(src) {
        let head = document.getElementsByTagName('head')[0];
        let script = document.createElement('script');
        script.type = 'text/javascript';
        script.src = src;
        head.appendChild(script);
    }
    */
}