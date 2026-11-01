import Constants from '../game/const.js';
export default function Log(s){
    Constants.loggingEnabled ? console.log( s ) : null;
}