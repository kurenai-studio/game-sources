import type { Nation, Role } from './types'

export const NATION_LABEL: Record<Nation, string> = { ussr: 'СССР', germany: 'Германия' }
export const ROLE_LABEL: Record<Role, string> = {
	light: 'лёгкий',
	medium: 'средний',
	heavy: 'тяжёлый',
	td: 'ПТ-САУ',
	spg: 'САУ',
}
