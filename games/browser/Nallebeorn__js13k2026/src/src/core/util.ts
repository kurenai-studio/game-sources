export function average(array: number[]) {
	return array.reduce((a, b) => a + b) / array.length;
}

export function ringPush<T>(array: T[], value: T, size: number) {
	if (array.push(value) > size) {
		array.shift();
	}
}

export function repeat(n: number): number[] {
	return Array.from({ length: n }, (_, i) => i);
}
