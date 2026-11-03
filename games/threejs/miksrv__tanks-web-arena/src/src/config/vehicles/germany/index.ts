import type { TankDef } from '../../types'
import { luchs } from './luchs'
import { pz4h } from './pz4h'
import { tiger } from './tiger'
import { kv1r } from './kv1r'
import { stug3 } from './stug3'
import { hummel } from './hummel'
import { pz2f } from './pz2f'
import { pz3j } from './pz3j'
import { panther } from './panther'
import { marder3 } from './marder3'
import { nashorn } from './nashorn'
import { ferdinand } from './ferdinand'
import { wespe } from './wespe'
import { pzwerfer } from './pzwerfer'
import { stuh42 } from './stuh42'

/** German vehicles in garage order (the second one is the garage's default pick). */
export const GERMANY_TANKS: TankDef[] = [
	luchs,
	pz4h,
	tiger,
	kv1r,
	stug3,
	hummel,
	pz2f,
	pz3j,
	panther,
	marder3,
	nashorn,
	ferdinand,
	wespe,
	pzwerfer,
	stuh42,
]
