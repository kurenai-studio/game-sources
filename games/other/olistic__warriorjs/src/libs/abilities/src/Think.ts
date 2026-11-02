import util from 'node:util';
import { Sense } from '@warriorjs/core';

import { type AbilityMeta } from './types.js';

class Think extends Sense {
  readonly description = 'Thinks out loud (`console.log` replacement).';
  readonly meta: AbilityMeta = {
    params: [{ name: 'args', type: 'any', rest: true }],
    returns: 'void',
  };

  perform(...args: unknown[]) {
    const thought = args.length > 0 ? util.format(...args) : 'nothing';
    this.unit.emit({ type: 'think', description: 'thinks {thought}', params: { thought } });
  }
}

export default Think;
