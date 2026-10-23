export function calculateDamage(impactX, impactY, targetX, targetY, blastRadius, maxDamage) {
  const dx = impactX - targetX;
  const dy = impactY - targetY;
  const distance = Math.sqrt(dx * dx + dy * dy);

  if (distance >= blastRadius) return 0;

  const factor = 1 - (distance / blastRadius);
  return Math.round(maxDamage * factor);
}

export function checkPartHit(impactX, impactY, cannon, blastRadius) {
  const barrelTip = cannon.getBarrelTip();
  const barrelDist = Math.sqrt(
    (impactX - barrelTip.x) ** 2 + (impactY - barrelTip.y) ** 2
  );

  const wheelLeftX = cannon.x - 8;
  const wheelRightX = cannon.x + 8;
  const wheelY = cannon.y;

  const wheelLeftDist = Math.sqrt(
    (impactX - wheelLeftX) ** 2 + (impactY - wheelY) ** 2
  );
  const wheelRightDist = Math.sqrt(
    (impactX - wheelRightX) ** 2 + (impactY - wheelY) ** 2
  );

  const result = { barrelHit: false, wheelHit: false };

  if (barrelDist < blastRadius * 0.5) {
    result.barrelHit = true;
  }
  if (wheelLeftDist < blastRadius * 0.4 || wheelRightDist < blastRadius * 0.4) {
    result.wheelHit = true;
  }

  return result;
}
