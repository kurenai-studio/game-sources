let Gm = {

    resources: 0,
    resourceCap: 0,
    income: 0,

    init: function() {
        console.log("You are the GM!");

        let cmds = document.createElement('div');
        cmds.id = 'gmCmds';
        document.getElementsByTagName('main')[0].appendChild(cmds);

        let gmCmdsEle = document.getElementById('gmCmds');

        let resourceEle = document.createElement('p');
        resourceEle.id = 'gmResources';
        resourceEle.innerHTML = 'Resources: ' + Gm.resources + '<br />Income: ' + Gm.income;
        gmCmdsEle.appendChild(resourceEle);

        gmCmdsEle.appendChild( Canvas.createButton('createBasic', 'cmdBtn', 'Spawn Basic (40)',
            function() {
                SocketIO.socket.emit('createEnemy', 'createBasic');
            }
        ) );
        gmCmdsEle.appendChild( Canvas.createButton('createFast', 'cmdBtn', 'Spawn Fast (120)',
            function() {
                SocketIO.socket.emit('createEnemy', 'createFast');
            }
        ) );

        setInterval(Gm.updateButtons, 20);
    },

    updateButtons: function() {
        document.getElementById("gmResources").innerHTML = 'Resources: ' + Gm.resources + ' / ' + Gm.resourceCap + '<br />Income: ' + Gm.income + "/Sec";
    },

    deInit: function() {
        let gmCmds = document.getElementById('gmCmds')
        document.getElementsByTagName('body')[0].removeChild(gmCmds);
    },

    disableButton: function(button) {
        button.className = 'cmdBtn disabled';
        button.disabled = true;
    },

    enableButton: function(button) {
        button.className = 'cmdBtn';
        button.disabled = false;
    }
}