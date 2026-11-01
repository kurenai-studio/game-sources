 export default class GameState {
    static get AudioEnabled() {
        return GameState._AudioEnabled;
    }
    static set AudioEnabled(enabled){
        GameState._AudioEnabled = enabled;
    }
    static get AudioVolume() {
        return GameState._AudioVolume;
    }
    static set AudioVolume(vol){
        GameState._AudioVolume = vol;
    }
    static get MusicVolume() {
        return GameState._MusicVolume;
    }
    static set MusicVolume(vol){
        GameState._MusicVolume = vol;
    }
 }

 GameState._AudioEnabled = true;
 GameState._AudioVolume = 0.15;
 GameState._MusicVolume = 0.10;
 