export function calculateAIShot(cannonX, cannonY, targetX, targetY, gravity, maxPower, errorFactor = 0.15, wind = 0, windCompensation = 0) {
  const dx = Math.abs(cannonX - targetX);
  const dy = targetY - cannonY;

  const baseAngle = (35 + Math.random() * 20) * Math.PI / 180;
  const tanA = Math.tan(baseAngle);
  const cosA = Math.cos(baseAngle);

  const denominator = 2 * cosA * cosA * (dx * tanA + dy);

  let power;
  if (denominator <= 0) {
    power = maxPower;
  } else {
    power = Math.sqrt(gravity * dx * dx / denominator);
  }

  power = Math.max(1, Math.min(power, maxPower));

  // Add random error
  const angle = baseAngle + (Math.random() - 0.5) * errorFactor;
  power = power * (1 + (Math.random() - 0.5) * errorFactor);
  power = Math.max(1, Math.min(power, maxPower));

  return { angle, power };
}

export function calculateBracketedShot(cannonX, cannonY, targetX, targetY, gravity, maxPower, errorFactor, wind, windCompensation, lastMiss) {
  const shot = calculateAIShot(cannonX, cannonY, targetX, targetY, gravity, maxPower, errorFactor, wind, windCompensation);

  if (!lastMiss) return shot;

  // Adjust based on where last shot landed relative to target
  const missDir = lastMiss.x - targetX;
  // If shot went too far right, reduce angle slightly and vice versa
  const correction = -Math.sign(missDir) * errorFactor * 0.3;
  shot.angle += correction;

  return shot;
}
