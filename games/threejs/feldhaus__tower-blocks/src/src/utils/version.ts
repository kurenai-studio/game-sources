// eslint-disable-next-line @typescript-eslint/naming-convention
declare const __VERSION__: string;

export function getVersion(): string {
  return __VERSION__ ?? '0.0.0';
}
