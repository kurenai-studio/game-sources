import { randomBytes } from "node:crypto";
import { Injectable } from "@nestjs/common";
import { hash, verify } from "@node-rs/argon2";

// argon2id (the library default) with the OWASP minimum: 19 MiB, 2 passes, 1 lane.
const OPTIONS = { memoryCost: 19_456, timeCost: 2, parallelism: 1 };

@Injectable()
export class PasswordService {
  private dummyHash?: Promise<string>;

  hash(password: string): Promise<string> {
    return hash(password, OPTIONS);
  }

  /** False for a wrong password and for a malformed stored hash. */
  async verify(storedHash: string, password: string): Promise<boolean> {
    try {
      return await verify(storedHash, password);
    } catch {
      return false;
    }
  }

  /** Does the work of a real check, so an unknown email takes as long as a wrong password. */
  async verifyAgainstDummy(password: string): Promise<void> {
    this.dummyHash ??= hash(randomBytes(16).toString("hex"), OPTIONS);
    await this.verify(await this.dummyHash, password);
  }
}
