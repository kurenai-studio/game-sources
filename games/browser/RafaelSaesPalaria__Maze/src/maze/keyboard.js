export class addKeyEventListener {
    constructor(context) {
        this.listeners = []
        addEventListener("keypress", (e) => {this.notifyAll(e)})
        addEventListener("keyup", (e) => {this.notifyAll(e)})
    }

    add(listener) {
        console.log("Listener added")
        this.listeners.push(listener)
    }

    notifyAll(e) {
        this.listeners.forEach(listener => {
            listener(e)
        })
    }
}