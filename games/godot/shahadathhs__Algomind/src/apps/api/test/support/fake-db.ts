import { randomUUID } from "node:crypto";
import type { PrismaService } from "../../src/core/prisma/prisma.service.js";

type Row = Record<string, unknown>;

/** A minimal in-memory stand-in for the tables the auth code uses. */
class Table {
  rows: Row[] = [];

  constructor(private readonly unique: string[]) {}

  private match(row: Row, where: Row): boolean {
    return Object.entries(where).every(([key, value]) => {
      if (value === null) return row[key] === null || row[key] === undefined;
      return row[key] === value;
    });
  }

  async findUnique({ where }: { where: Row }): Promise<Row | null> {
    return this.rows.find((row) => this.match(row, where)) ?? null;
  }

  async create({ data }: { data: Row }): Promise<Row> {
    for (const key of this.unique) {
      if (this.rows.some((row) => row[key] === data[key])) {
        throw Object.assign(new Error("Unique constraint failed"), { code: "P2002" });
      }
    }
    const row = { id: randomUUID(), createdAt: new Date(), revokedAt: null, ...data };
    this.rows.push(row);
    return row;
  }

  async update({ where, data }: { where: Row; data: Row }): Promise<Row> {
    const row = await this.findUnique({ where });
    if (!row) throw new Error("not found");
    Object.assign(row, data);
    return row;
  }

  async updateMany({ where, data }: { where: Row; data: Row }): Promise<{ count: number }> {
    const matching = this.rows.filter((row) => this.match(row, where));
    for (const row of matching) Object.assign(row, data);
    return { count: matching.length };
  }
}

export class FakeDb {
  user = new Table(["email"]);
  refreshToken = new Table(["tokenHash"]);

  async $transaction<T>(work: (tx: FakeDb) => Promise<T>): Promise<T> {
    return work(this);
  }

  asPrisma(): PrismaService {
    return this as unknown as PrismaService;
  }
}
