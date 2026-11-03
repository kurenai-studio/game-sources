export enum Env {
  DEV = 'development',
  PROD = 'production',
}

// eslint-disable-next-line @typescript-eslint/naming-convention
declare const __ENV__: Env;

export function getEnv(): Env {
  return __ENV__ ?? Env.PROD;
}
