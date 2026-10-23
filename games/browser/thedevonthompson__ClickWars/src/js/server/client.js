let Client = {

    playerList: [],
    spectatorList: [],

    gmId: NaN,

    create: function(id) {
        if (!Client.exists(id, "spectatorList")) {
            this.id = id;
            this.mouseX = NaN;
            this.mouseY = NaN;

            Client.spectatorList.push(this);
        }
    },

    moveToPlayerList: function(id) {
        if (Client.exists(id, "spectatorList")) {
            let client = Client.remove(id, "spectatorList");
            Client.playerList.push(client);
            if (Client.playerList.length >= 1) {
                Client.gmId = Client.playerList[0].id;
            }
        }
    },

    exists: function(id, list) {
        return Client[list].some(function(client) {
            if (client.id === id) {
                return true;
            }
        });
    },

    findList: function(id) {
        if (Client.exists(id, "playerList")) {
            return "playerList";
        } else if (Client.exists(id, "spectatorList")) {
            return "spectatorList";
        }
    },

    setGm: function(id) {
        if (Client.exists(id)) {
            Client.playerList.unshift( Client.remove(id) );
        }
    },

    updateGm: function() {
        if (Client.playerList.length > 0) {
            Client.gmId = Client.playerList[0].id;
        } else {
            Client.gmId = NaN;
        }
    },

    remove: function(id, list) {
        let client = null;
        Client[list].some(function(c, index) {
            if (c.id === id) {
                client = Client[list].splice(index, 1);
                return true;
            }
        });
        return client[0];
    }
}

module.exports = Client;