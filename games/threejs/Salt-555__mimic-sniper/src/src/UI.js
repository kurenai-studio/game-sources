export class UI {
  constructor() {
    this.startScreen = document.querySelector('#startScreen');
    this.roundEnd = document.querySelector('#roundEnd');
    this.winner = document.querySelector('#winnerText');
    this.summary = document.querySelector('#roundSummary');
    this.timer = document.querySelector('#timer');
    this.stateLabel = document.querySelector('#stateLabel');
    this.ammo = document.querySelector('#ammo');
    this.breathFill = document.querySelector('#breathFill');
    this.scope = document.querySelector('#scope');
    this.prompt = document.querySelector('#targetPrompt');
  }

  update(machine, sniper, target) {
    const seconds = Math.ceil(machine.timeRemaining);
    this.timer.textContent = `0${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;
    this.stateLabel.textContent = machine.state === 'playing' ? 'LIVE ROUND' : machine.state.toUpperCase();
    this.ammo.textContent = sniper.weapon.reloading ? 'RELOADING' : `${sniper.weapon.ammo} / ${sniper.weapon.reserve}`;
    this.breathFill.style.width = `${sniper.breath}%`;
    this.scope.classList.toggle('visible', sniper.scoped);
    this.prompt.classList.toggle('visible', Boolean(target));
    this.prompt.textContent = target ? `E // COPY ${target.userData.propType.toUpperCase()}` : 'NO COPY TARGET';
  }

  showEnd(winner, sniper) {
    this.roundEnd.classList.add('visible');
    this.winner.textContent = winner === 'sniper' ? 'MIMIC ELIMINATED' : 'MIMIC ESCAPED';
    const accuracy = sniper.shots ? Math.round((sniper.hits / sniper.shots) * 100) : 0;
    this.summary.textContent = `${sniper.shots} shots fired // ${accuracy}% confirmed accuracy`;
  }
}
