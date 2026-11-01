//TODO: Language Pack loading, Associative array
var _gameName = "Mister Barista";
var _version = "v0.01";
var _winner = "Winner!";
var _notThisOne = "Not this one... Try Again";
var _checkingCup = "Checking cup...";
var _coins = "Coins";
var _useMockServer = true; 
var _loggingEnabled = true; 
var _coinOffset = -135; //offset of coin above cup

export default class Constants {
  static get useMockServer(){
    return _useMockServer;
  }
  static get loggingEnabled(){
    return _loggingEnabled;
  }
  static gameName() {
    return _gameName;
  }
  static winner() {
    return _winner;
  }
  static notThisOne() {
    return _notThisOne;
  }
  static checkingCup() {
    return _checkingCup;
  }
  static version() {
    return _version;
  }
  static coins() {
    return _coins;
  }
  static get coinOffset() {
    return _coinOffset;
  }
}