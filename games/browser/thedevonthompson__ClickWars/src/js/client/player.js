let Player = {

    x: NaN,
    y: NaN,

    init: function() {
        
        // Track mouse coords
        document.onmousemove = function(event) {

            let newX = event.pageX - Canvas.xOffset;
            let newY = event.pageY - Canvas.yOffset;

            // Set own coords
            Player.x = newX;
            Player.y = newY;

            // Emit coords to the server.
            SocketIO.emitMovement(newX, newY);
        }

        // Detect collision client side or server side?
        document.getElementById("ClickWars").addEventListener('click', Player.onClickRemoveEnemy);
    },

    deInit: function() {
        document.onmousemove = null;
        document.getElementById("ClickWars").removeEventListener('click', Player.onClickRemoveEnemy);
    },

    onClickRemoveEnemy: function() {
        SocketIO.enemyList.map(function(enemy, index) {
            
            // Circle collision detection
            let distance = Math.sqrt( (Player.x - enemy.x) * (Player.x - enemy.x) + (Player.y - enemy.y) * (Player.y - enemy.y) );
            if (distance <= enemy.radius * 1.5) {
                SocketIO.removeEnemy(enemy.id);
            }

            /* Square collision detection
            if (Player.x >= enemy.x + enemy.leftEdge && Player.x <= enemy.x + enemy.rightEdge) {
                if (Player.y >= enemy.y + enemy.topEdge && Player.y <= enemy.y + enemy.bottomEdge) {
                    SocketIO.removeEnemy(enemy.id);
                }
            }
            */
        });
    }
}