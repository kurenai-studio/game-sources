import Player from "../player";
import Status from "../status";
import { StatusesFormat } from "./data-handler.types";

export default class DataHandler {
  player: Player;
  actions = ["statuses"];

  constructor(player: Player) {
    this.player = player;
  }

  public getMessage(message: string) {
    const json = JSON.parse(message);
    // console.log("got", json);
    const found = this.actions.find((action) => action === json.name);
    switch(found){
      case "statuses":
        const statusesData : StatusesFormat = json;
        // console.log("statusesData",statusesData);
        
        this.player.statuses = statusesData.statuses.map(({name,value}) => {
          // console.log(name, value);
          
          return new Status(name, value);
        });
    }
  }
}
