local data = {
	-- region position and sizes
	diskCF = CFrame.new(),
	diskSize = Vector3.new(100, 2, 100),
	haloCF = CFrame.new(),
	haloSize = Vector3.new(80, 40, 80),
	longBarCF = CFrame.fromOrientation(0, 60, 0),
	longBarSize = Vector3.new(4, 2, 16),
	shortBarCF = CFrame.fromOrientation(0, 90, 0),
	shortBarSize = Vector3.new(4, 1, 10),
	centerBulgeCF = CFrame.new(),
	centerBulgeSize = Vector3.new(24, 16, 24),
	sagdegCF = CFrame.fromOrientation(0, -20, 15) + Vector3.new(-31, -35, -13),
	sagdegSize = Vector3.new(4, 12, 8),
	umadsgCF = CFrame.fromOrientation(60, 0, -60) + Vector3.new(0, 100, -25),--Vector3.new(-50, 50, 100),
	umadsgSize = Vector3.new(4, 8, 4),
	boodsgCF = CFrame.new(-50, 0, 100),
	boodsgSize = Vector3.new(4, 4, 4),
	lmcCF = CFrame.fromOrientation(45, -30, 30) + Vector3.new(66, -31, -14),
	lmcSize = Vector3.new(24, 8, 16),
	smcCF = CFrame.fromOrientation(-25, 85, 50) + Vector3.new(58, -53, -56),
	smcSize = Vector3.new(8, 4, 16),

	-- other constants
	spiralRadius = 40,		-- how far the main spiral arms go out
	spiralRatio = 1.2,		-- spiral ratio for the long arms
	armWidth = 4,			-- max arm width
	orionArmWidth = 3,		-- max width for the orion arm
	armScale = 1,			-- default parameter bound (t = [0, 1])
	outerArmScale = 1.5,	-- higher bound for the outer arm (t = [0, 1.5])
	orionArmScale = 0.825,	-- to place the orion arm between the main arms
	orionStart = 0.6,		-- lower bound for the orion arm
	orionEnd = 0.9,			-- upper bound for the orion arm
	tangentDt = 0.001,		-- how far to go when calculating the tangent vector at a given position along a spiral arm
	lmcSpiralDist = 0.9,	-- % of stars in the LMC that are part of its spiral

	-- star distribution ratios
	mainarm = 0.14, -- x3
	outerarm = 0.16, -- x1
	minorarm = 0.04,
	bulge = 0.1,
	disk = 0,
	bar = 0.1,
	smc = 0.01,
	lmc = 0.04, --0.05
	sagdeg = 0.02,
	boodsg = 0.005,
	umadsg = 0.005,
	globular = 0.075,
	numberOfClusters = 30--math.random(10, 30)
}

data.longBarAxis = data.longBarSize.z / 2
data.shortBarAxis = data.shortBarSize.z / 2
data.orionAxis = (data.orionEnd - data.orionStart) / 2
data.lmcAxis = Vector3.new(data.lmcSize.x / 2, data.lmcSize.z, data.lmcSize.x)

local sum = data.mainarm * 3 + data.outerarm + data.minorarm + data.bulge + data.disk + data.bar + data.smc + data.lmc + data.sagdeg + data.boodsg + data.umadsg + data.globular
data.mainarm = data.mainarm / sum
data.outerarm = data.outerarm / sum
data.minorarm = data.minorarm / sum
data.bulge = data.bulge / sum
data.disk = data.disk / sum
data.bar = data.bar / sum
data.smc = data.smc / sum
data.lmc = data.lmc / sum
data.sagdeg = data.sagdeg / sum
data.boodsg = data.boodsg / sum
data.umadsg = data.umadsg / sum
data.globular = data.globular / sum

local arms = {}

local function armPosition(t, origin, width, scale, isShort)
	local t1 = t * math.pi * 2 / (isShort and 1 or data.spiralRatio) * scale
	local r1 = t * data.spiralRadius * data.spiralRatio * scale
	return (origin * CFrame.angles(0, t1, 0) * CFrame.new(r1 * Model.sign(width), 0, width)).p
end
-- direction an arm is pointing at t
local function armTangent(t, r, origin, width, scale, isShort)
	if (t == 0) then
		return origin.rightVector * Model.sign(width)
	else
		local r0 = armPosition(math.max(0, t - data.tangentDt), origin, width, scale, isShort)
		return (r - r0).unit
	end
end
-- width of a galaxy arm at t
local function mainArmSize(t)
	local w = math.sqrt(t)
	local dr = math.sqrt(1 - t ^ 2)
	return w * dr
end
-- width for the norma/outer arm which stretches a little further
local function outerArmSize(t)
	local w = math.sqrt(t)
	--local dr = (t <= 0.5) and 1 or math.sqrt(0.25 - (t - 0.5) ^ 2) + 0.5
	local dr = (t <= 0.5) and 1 or math.sqrt(0.25 - (t - 0.5) ^ 2) * 2
	return w * dr
end

-- position along the orion arm
local function orionPosition(t)
	local t1 = t * math.pi * 2
	local r1 = t * data.spiralRadius * data.spiralRatio
	return (data.shortBarCF * CFrame.angles(0, t1, 0) * CFrame.new(r1 * data.orionArmScale, 0, data.shortBarAxis)).p
end
-- direction for the orion arm
local function orionTangent(t, r)
	if (t == 0) then
		return data.shortBarCF.rightVector
	else
		local r0 = orionPosition(math.max(0, t - data.tangentDt))
		return (r - r0).unit
	end
end
-- width of the orion arm
local function orionArmSize(t)
	if (t >= data.orionStart and t <= data.orionEnd) then
		return t ^ 3 / data.orionAxis * math.sqrt(data.orionAxis ^ 2 - (t - data.orionStart - data.orionAxis) ^ 2)
	else
		return 0
	end
end

-- position along the LMC spiral (t = (-1, 1))
local function lmcSpiralPosition(t)
	local th = t * math.pi * 0.5
	local r = math.abs(t) ^ (1 / 4) * Model.sign(t)
	local x = r * math.cos(th)
	local z = r * math.sin(th) * Model.sign(r)
	return Vector3.new(x, 0, z)
end
local function lmcTangent(t)
	return (lmcSpiralPosition(t - data.tangentDt) - lmcSpiralPosition(t + data.tangentDt)).unit
end
local function lmcArmSize(t)
	return math.cos(t * math.pi / 2) * 0.125
end

function arms.lmcSpiral(t)
	local r = lmcSpiralPosition(t)
	local lv = lmcTangent(t)
	local w = lmcArmSize(t)
	return r, lv, w
end

function arms.outerArm(t)
	-- position along arm at 't'
	local r = armPosition(t, data.longBarCF, data.longBarAxis, data.outerArmScale)
	-- tangent direction
	local lv = armTangent(t, r, data.longBarCF, data.longBarAxis, data.outerArmScale)
	-- diameter of the cross section
	local w = outerArmSize(t)
	return r, lv, w
end

function arms.sagittariusArm(t)
	-- position along arm at 't'
	local r = armPosition(t, data.longBarCF, -data.longBarAxis, data.armScale)
	-- tangent direction
	local lv = armTangent(t, r, data.longBarCF, -data.longBarAxis, data.armScale)
	-- diameter of the cross section
	local w = mainArmSize(t)
	return r, lv, w
end

function arms.perseusArm(t)
	-- position along arm at 't'
	local r = armPosition(t, data.shortBarCF, data.shortBarAxis, data.armScale, true)
	-- tangent direction
	local lv = armTangent(t, r, data.shortBarCF, data.shortBarAxis, data.armScale, true)
	-- diameter of the cross section
	local w = mainArmSize(t)
	return r, lv, w
end

function arms.centaurusArm(t)
	-- position along arm at 't'
	local r = armPosition(t, data.shortBarCF, -data.shortBarAxis, data.armScale, true)
	-- tangent direction
	local lv = armTangent(t, r, data.shortBarCF, -data.shortBarAxis, data.armScale, true)
	-- diameter of the cross section
	local w = mainArmSize(t)
	return r, lv, w
end

function arms.orionArm(t)
	local globalT = t * (data.orionEnd - data.orionStart) + data.orionStart
	-- position along arm at 't'
	local r = orionPosition(globalT)
	-- tangent direction
	local lv = orionTangent(globalT, r)
	-- diameter of the cross section
	local w = orionArmSize(globalT)
	return r, lv, w
end

------------------------------------------------------------------------

local function randomPointInEllipsoid(size, d)
	local theta = 2 * math.pi * math.random()
	-- latitude (arc cosine prevents stars from clustering around the north and south poles)
	local phi = math.acos((2 * math.random()) - 1)-- - math.pi / 2
	-- distance (square root prevents stars from clustering around the origin)
	-- d = 2: even distribution
	-- d < 2: stars concentrated around center
	-- d > 2: stars concentrated around surface
	local r = math.random() ^ (1 / d)

	return Vector3.new(
		r * math.sin(phi) * math.cos(theta),
		r * math.sin(phi) * math.sin(theta),
		r * math.cos(phi)
	) * size / 2
end

local generate = {}

function generate.outerArm(n)
	local results = {}
	local t, r, lv, w, theta, radius
	for i = 1, math.floor(n * data.outerarm) do
		t = math.random()
		r, lv, w = arms.outerArm(t)
		theta = math.random() * 2 * math.pi
		radius = math.sqrt(math.random()) * w
		results[i] = (CFrame.lookAlong(r, lv) * CFrame.angles(0, 0, theta) * CFrame.new(0, radius * data.armWidth, 0)).p
	end
	return results
end

function generate.sagittariusArm(n)
	local results = {}
	local t, r, lv, w, theta, radius
	for i = 1, math.floor(n * data.mainarm) do
		t = math.random()
		r, lv, w = arms.sagittariusArm(t)
		theta = math.random() * 2 * math.pi
		radius = math.sqrt(math.random()) * w
		results[i] = (CFrame.lookAlong(r, lv) * CFrame.angles(0, 0, theta) * CFrame.new(0, radius * data.armWidth, 0)).p
	end
	return results
end

function generate.perseusArm(n)
	local results = {}
	local t, r, lv, w, theta, radius
	for i = 1, math.floor(n * data.mainarm) do
		t = math.random()
		r, lv, w = arms.perseusArm(t)
		theta = math.random() * 2 * math.pi
		radius = math.sqrt(math.random()) * w
		results[i] = (CFrame.lookAlong(r, lv) * CFrame.angles(0, 0, theta) * CFrame.new(0, radius * data.armWidth, 0)).p
	end
	return results
end

function generate.centaurusArm(n)
	local results = {}
	local t, r, lv, w, theta, radius
	for i = 1, math.floor(n * data.mainarm) do
		t = math.random()
		r, lv, w = arms.centaurusArm(t)
		theta = math.random() * 2 * math.pi
		radius = math.sqrt(math.random()) * w
		results[i] = (CFrame.lookAlong(r, lv) * CFrame.angles(0, 0, theta) * CFrame.new(0, radius * data.armWidth, 0)).p
	end
	return results
end

function generate.orionArm(n)
	local results = {}
	local t, r, lv, w, theta, radius
	for i = 1, math.floor(n * data.minorarm) do
		t = math.random()
		r, lv, w = arms.orionArm(t)
		theta = math.random() * 2 * math.pi
		radius = math.sqrt(math.random()) * w
		results[i] = (CFrame.lookAlong(r, lv) * CFrame.angles(0, 0, theta) * CFrame.new(0, radius * data.orionArmWidth, 0)).p
	end
	return results
end

function generate.disk(n)
	local results = {}
	for i = 1, math.floor(n * data.disk) do
		results[i] = data.diskCF * randomPointInEllipsoid(data.diskSize, 3)
	end
	return results
end

function generate.center(n)
	local results = {}
	local bn = math.floor(n * data.bar)
	for i = 1, bn do
		results[i] = data.longBarCF * randomPointInEllipsoid(data.longBarSize, 3)
	end
	local p
	for j = 1, math.floor(n * data.bulge) do
		--repeat
		p = randomPointInEllipsoid(data.centerBulgeSize, 2)
		--until (not isPointInEllipsoid(data.longBarSize, p))
		results[bn + j] = data.centerBulgeCF * p
	end
	return results
end

function generate.globularClusters(n)
	local results = {}
	local gclusterstarpool = math.floor(n * data.globular)
	local starsThisCluster
	local topOrBottom = 1
	local currentCluster
	while (gclusterstarpool > 0) do
		starsThisCluster = math.min(gclusterstarpool, math.max(1, math.floor(data.globular * n / data.numberOfClusters * (0.75 + math.random() * 0.5))))
		currentCluster = {}
		gclusterstarpool = gclusterstarpool - starsThisCluster
		local theta = 2 * math.pi * math.random()
		local phi = math.acos((math.random() * 0.5 + 0.5) * (-1) ^ topOrBottom)
		topOrBottom = topOrBottom + 1
		local d = math.random() ^ (1 / 5)

		local r = Vector3.new(
			d * math.sin(phi) * math.cos(theta),
			d * math.cos(phi),
			d * math.sin(phi) * math.sin(theta)
		) * data.haloSize / 2

		for i = 1, starsThisCluster do
			local theta2 = 2 * math.pi * math.random()
			local phi2 = math.acos((2 * math.random()) - 1)
			local d2 = math.random() ^ (1 / 1)

			local r2 = Vector3.new(
				d2 * math.sin(phi2) * math.cos(theta2),
				d2 * math.cos(phi2),
				d2 * math.sin(phi2) * math.sin(theta2)
			) * 2

			table.insert(currentCluster, r + r2)
		end
		table.insert(results, currentCluster)
	end
	return results
end

function generate.lmc(n)
	local results = {}
	local sn = math.floor(n * data.lmc * data.lmcSpiralDist)
	local t, r, lv, w, theta, radius, cr
	for i = 1, sn do
		t = math.random() * 2 - 1
		t = math.abs(t) ^ (4 / 1) * Model.sign(t)
		r, lv, w = arms.lmcSpiral(t)
		theta = math.random() * 2 * math.pi
		radius = math.sqrt(math.random())
		cr = Vector3.new(radius * math.cos(theta), radius * math.sin(theta), 0)
		results[i] = (data.lmcCF * CFrame.lookAlong(r * data.lmcSize / 2, lv) * CFrame.new(cr * data.lmcAxis * w)).p
	end
	for j = 1, math.floor(n * data.lmc - sn) do
		results[sn + j] = data.lmcCF * randomPointInEllipsoid(data.lmcSize, 3)
	end
	return results
end

function generate.smc(n)
	local results = {}
	for i = 1, math.floor(n * data.smc) do
		results[i] = data.smcCF * randomPointInEllipsoid(data.smcSize, 1)
	end
	return results
end

function generate.sagdeg(n)
	local results = {}
	for i = 1, math.floor(n * data.sagdeg) do
		results[i] = data.sagdegCF * randomPointInEllipsoid(data.sagdegSize, 1)
	end
	return results
end

function generate.boodsg(n)
	local results = {}
	for i = 1, math.floor(n * data.boodsg) do
		results[i] = data.boodsgCF * randomPointInEllipsoid(data.boodsgSize, 1)
	end
	return results
end

function generate.umadsg(n)
	local results = {}
	for i = 1, math.floor(n * data.umadsg) do
		results[i] = data.umadsgCF * randomPointInEllipsoid(data.umadsgSize, 1)
	end
	return results
end

return function(maxCount, seed)
	local dl = math.floor(math.log10(maxCount)) + 1
	local nc = "%0" .. dl .. "d"
	local galaxy = {
		all = {},
		center = {
			name = "Galactic Center",
			sym = "GN-" .. nc
		},
		disk = {
			name = "Glactic Disk",
			sym = "GD-" .. nc
		},
		outerArm = {
			name = "Outer Arm",
			sym = "OUT-" .. nc
		},
		sagittariusArm = {
			name = "Sagittarius Arm",
			sym = "SGR-" .. nc
		},
		perseusArm = {
			name = "Perseus Arm",
			sym = "PER-" .. nc
		},
		centaurusArm = {
			name = "Centaurus Arm",
			sym = "CEN-" .. nc
		},
		orionArm = {
			name = "Orion Arm",
			sym = "ORI-" .. nc
		},
		lmc = {
			name = "Large Magellanic Cloud",
			sym = "LMC-" .. nc
		},
		smc = {
			name = "Small Magellanic Cloud",
			sym = "SMC-" .. nc
		},
		sagdeg = {
			name = "Sagittarius Galaxy",
			sym = "SAGDEG-" .. nc
		},
		boodsg = {
			name = "Bootes Galaxy",
			sym = "BOODEG-" .. nc
		},
		umadsg = {
			name = "Ursa Major Galaxy",
			sym = "UMADEG-" .. nc
		}
	}
	math.randomseed(seed)
	local index = 1
	local star
	for _, fn in ipairs({"center", "disk", "outerArm", "sagittariusArm", "perseusArm", "centaurusArm", "orionArm", "lmc", "smc", "sagdeg", "boodsg", "umadsg"}) do
		for i, p in ipairs(generate[fn](maxCount)) do
			star = {
				index = index,
				position = p,
				seed = math.floor(math.random() * 1000000000),
				name = string.format(galaxy[fn].sym, i),
				region = fn
			}
			table.insert(galaxy.all, star)
			table.insert(galaxy[fn], star)
			index = index + 1
		end
	end
	for i, gc in ipairs(generate.globularClusters(maxCount)) do
		local name = string.format("GC-%02d", i)
		local set = {
			name = "Globular Cluster " .. name,
			sym = name .. "-" .. nc
		}
		for j, p in ipairs(gc) do
			star = {
				index = index,
				position = p,
				seed = math.floor(math.random() * 1000000000),
				name = string.format(set.sym, j),
				region = string.lower(name)
			}
			table.insert(galaxy.all, star)
			table.insert(set, star)
			index = index + 1
		end
		galaxy[string.lower(name)] = set
	end
	return galaxy
end
