# Pottery workshop wheel for hole 4: "wheel" (turning disc with a thrown pot, radius 1.5 m, pot radius
# 0.32 m to match the physics) and "housing" (static kick-wheel base, stool and a shelf of pots).
clay = mat("clay", "#A8623C"); clay2 = mat("clay_dark", "#8C4F30"); wood = mat("wood", "#B98A63"); wood2 = mat("wood_dark", "#8F6744"); stone = mat("stone", "#C9A882"); dark = mat("dark", "#2E221B")
disc = cyl(1.5, 1.5, 0.1, (0, 0, 0.05), wood, n=24)
disc.data.materials.append(wood2)
for p in disc.data.polygons:
    c = p.center
    if abs(p.normal.z) > 0.9:
        a = math.atan2(c.y, c.x)
        p.material_index = int((a + math.pi) / (math.pi / 6)) % 2
rings = [cyl(r, r, 0.012, (0, 0, 0.105), wood2, n=24) for r in (0.5, 0.9, 1.3)]
hub = cyl(0.42, 0.45, 0.06, (0, 0, 0.13), stone, n=12)
belly = cyl(0.22, 0.32, 0.3, (0, 0, 0.31), clay, n=12)
shoulder = cyl(0.18, 0.22, 0.12, (0, 0, 0.52), clay, n=12)
neck = cyl(0.21, 0.17, 0.1, (0, 0, 0.63), clay2, n=12)
lip = cyl(0.23, 0.21, 0.04, (0, 0, 0.70), clay, n=12)
mouth = cyl(0.15, 0.15, 0.02, (0, 0, 0.72), dark, n=12)
origin_bottom(join([disc, hub, belly, shoulder, neck, lip, mouth] + rings, "wheel"))
# static housing: a worn stone ring and a kick-wheel axle block
base = cyl(1.62, 1.72, 0.08, (0, 0, -0.04), stone, n=24)
axle = cyl(0.2, 0.26, 0.5, (0, 0, -0.3), wood2, n=8)
stool = [box((0.4, 0.4, 0.05), (1.95, 0.3, 0.4), wood2)] + [cyl(0.03, 0.03, 0.4, (1.95 + sx * 0.15, 0.3 + sy * 0.15, 0.2), wood2, n=4) for sx in (-1, 1) for sy in (-1, 1)]
origin_bottom(join([base, axle] + stool, "housing"))
