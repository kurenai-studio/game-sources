export function chooseTransformTarget(candidates, range) {
  const eligible = candidates.filter((candidate) => candidate.eligible && candidate.distance <= range);
  const highlighted = eligible.find((candidate) => candidate.highlighted);
  if (highlighted) return highlighted;
  return eligible.sort((a, b) => a.distance - b.distance)[0] ?? null;
}
