/**
 * The acts of the campaign: stretches of worlds with one character, so a list of twenty worlds has
 * a shape. They are read from a world's number, so a world the dashboard adds later belongs to the
 * last act until this list says otherwise.
 */
export type Act = { title: string; from: number; to: number; text: string };

export const ACTS: Act[] = [
  { title: "The tape", from: 1, to: 4, text: "Order, turns, and doing a thing again." },
  {
    title: "Choosing and naming",
    from: 5,
    to: 9,
    text: "Look, decide, name a part, fix a program.",
  },
  {
    title: "Counting and covering",
    from: 10,
    to: 12,
    text: "Numbers, memory, and leaving nothing out.",
  },
  {
    title: "The board pushes back",
    from: 13,
    to: 18,
    text: "Guards, keys, crates, switches, ice and shortcuts.",
  },
  {
    title: "Putting it together",
    from: 19,
    to: 99,
    text: "A procedure that calls itself, and every tool at once.",
  },
];

export function actOf(worldNumber: number): Act {
  return ACTS.find((a) => worldNumber >= a.from && worldNumber <= a.to) ?? ACTS[ACTS.length - 1]!;
}

/** Groups worlds by act, in order, keeping only the acts that have a world. */
export function groupByAct<T extends { number: number }>(worlds: T[]): { act: Act; worlds: T[] }[] {
  return ACTS.map((act) => ({ act, worlds: worlds.filter((w) => actOf(w.number) === act) })).filter(
    (group) => group.worlds.length > 0,
  );
}
