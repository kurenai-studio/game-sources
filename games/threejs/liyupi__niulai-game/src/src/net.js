/**
 * 局域网联机客户端 —— 主机权威架构
 * 主机：运行完整模拟，30Hz 广播状态快照；接收客机输入
 * 客机：本地输入 30Hz 上行；接收快照驱动木偶（插值平滑渲染）
 */
export class NetSession {
  constructor(handlers) {
    this.ws = null;
    this.role = null;         // 'host' | 'guest'
    this.handlers = handlers; // { onRole, onMatched, onPick, onReady, onStart, onCmd, onState, onInput, onClose }
    this._inputTimer = null;
    this._stateTimer = null;
  }

  connect() {
    return new Promise((resolve, reject) => {
      const proto = location.protocol === 'https:' ? 'wss' : 'ws';
      const ws = this.ws = new WebSocket(`${proto}://${location.host}`);
      const timeout = setTimeout(() => reject(new Error('连接超时')), 5000);
      ws.onopen = () => { clearTimeout(timeout); resolve(); };
      ws.onerror = () => { clearTimeout(timeout); reject(new Error('无法连接服务器')); };
      ws.onclose = () => {
        this._stopTimers();
        this.handlers.onClose?.();
      };
      ws.onmessage = (e) => {
        let msg;
        try { msg = JSON.parse(e.data); } catch { return; }
        this.rxCount = (this.rxCount || 0) + 1;
        this.lastRx = msg.type;
        this._route(msg);
      };
    });
  }

  _route(msg) {
    const h = this.handlers;
    switch (msg.type) {
      case 'role': this.role = msg.role; h.onRole?.(msg.role); break;
      case 'matched': h.onMatched?.(); break;
      case 'pick': h.onPick?.(msg.from, msg.char); break;
      case 'ready': h.onReady?.(msg.from, msg.char); break;
      case 'cmd': h.onStart?.(msg); break;
      case 'state': if (this.role === 'guest') h.onState?.(msg); break;
      case 'input': if (this.role === 'host') h.onInput?.(msg.keys); break;
      case 'peer-left': h.onClose?.(true); break;
    }
  }

  send(obj) {
    if (this.ws && this.ws.readyState === 1) {
      this.ws.send(JSON.stringify(obj));
      this.txCount = (this.txCount || 0) + 1;
      if (obj.type === 'state') this.stateTx = (this.stateTx || 0) + 1;
    }
  }

  /** 客机：上行输入 */
  startInputLoop(getInput) {
    this._stopTimer('_inputTimer');
    this._getInput = getInput;
    this._inputTimer = setInterval(() => {
      if (this.role !== 'guest') return;
      this.send({ type: 'input', keys: this._getInput() });
    }, 33);
  }

  /** 主机：下行状态快照 */
  startStateLoop(getState) {
    this._stopTimer('_stateTimer');
    this._getState = getState;
    this._stateTimer = setInterval(() => {
      if (this.role !== 'host') return;
      const data = this._getState();
      if (data) this.send({ type: 'state', ...data });
    }, 33);
  }

  _stopTimer(key) { if (this[key]) { clearInterval(this[key]); this[key] = null; } }
  _stopTimers() { this._stopTimer('_inputTimer'); this._stopTimer('_stateTimer'); }

  /** 停止数据循环（保留连接） */
  stopLoops() { this._stopTimers(); }

  destroy() {
    this._stopTimers();
    if (this.ws) { try { this.ws.close(); } catch {} this.ws = null; }
  }
}
