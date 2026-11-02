"""Astro Drift — Panda 3D edition.

3D restatement of the drifting-ship demo. The ship is a box mesh translated
on the XY plane (Z up) with screen-wrap at world bounds. Demonstrates Panda 3D
fundamentals: ShowBase, task scheduler, lighting, keyboard input.
"""

import math

from direct.gui.OnscreenText import OnscreenText
from direct.showbase.ShowBase import ShowBase
from direct.task import Task
from panda3d.core import (
	AmbientLight,
	DirectionalLight,
	LineSegs,
	TextNode,
	Vec3,
	Vec4,
	WindowProperties,
)


WORLD_BOUND = 12.0


class AstroDrift3D(ShowBase):
	def __init__(self) -> None:
		super().__init__()
		props = WindowProperties()
		props.setTitle("Astro Drift — Panda 3D")
		props.setSize(960, 540)
		self.win.requestProperties(props)

		self.disableMouse()
		self.set_background_color(0.04, 0.05, 0.09, 1)

		self.ship = self.loader.loadModel("models/box")
		self.ship.setScale(0.5, 1.0, 0.25)
		self.ship.setPos(-0.25, -0.5, -0.125)
		self.ship_pivot = self.render.attachNewNode("ship_pivot")
		self.ship.reparentTo(self.ship_pivot)
		self.ship.setColor(0.92, 0.96, 1.0, 1)

		amb = AmbientLight("amb")
		amb.setColor(Vec4(0.25, 0.27, 0.34, 1))
		self.render.setLight(self.render.attachNewNode(amb))
		dl = DirectionalLight("dl")
		dl.setColor(Vec4(0.85, 0.9, 1.0, 1))
		dln = self.render.attachNewNode(dl)
		dln.setHpr(45, -50, 0)
		self.render.setLight(dln)

		self._draw_world_grid()

		self.camera.setPos(0, -28, 14)
		self.camera.lookAt(0, 0, 0)

		OnscreenText(
			text="Astro Drift — Panda 3D",
			pos=(-1.75, 0.92), scale=0.055,
			fg=(0.92, 0.96, 1.0, 1), align=TextNode.ALeft, mayChange=False,
		)
		OnscreenText(
			text="← → rotate   |   ↑ thrust   |   ↓ brake   |   Esc quit",
			pos=(0, -0.94), scale=0.05,
			fg=(0.62, 0.7, 0.85, 1), align=TextNode.ACenter, mayChange=False,
		)

		self.velocity = Vec3(0, 0, 0)
		self.heading = 0.0

		self.keys = {"arrow_up": False, "arrow_down": False, "arrow_left": False, "arrow_right": False}
		for k in self.keys:
			self.accept(k, self._set_key, [k, True])
			self.accept(f"{k}-up", self._set_key, [k, False])
		self.accept("escape", self.user_exit)

		self.taskMgr.add(self._update, "update")

	def _set_key(self, key: str, value: bool) -> None:
		self.keys[key] = value

	def _draw_world_grid(self) -> None:
		segs = LineSegs("grid")
		segs.setColor(0.12, 0.16, 0.28, 1)
		segs.setThickness(1.0)
		step = 2.0
		for i in range(-int(WORLD_BOUND), int(WORLD_BOUND) + 1, 2):
			segs.moveTo(i, -WORLD_BOUND, 0)
			segs.drawTo(i, WORLD_BOUND, 0)
			segs.moveTo(-WORLD_BOUND, i, 0)
			segs.drawTo(WORLD_BOUND, i, 0)
		self.render.attachNewNode(segs.create())

	def _update(self, task) -> int:
		dt = globalClock.getDt()
		ROT, THRUST_F, DRAG, BRAKE, MAX_SPEED = 90.0, 9.0, 0.55, 0.08, 12.0

		rot_input = 0.0
		if self.keys["arrow_left"]:
			rot_input -= 1.0
		if self.keys["arrow_right"]:
			rot_input += 1.0
		self.heading += rot_input * ROT * dt

		thrusting = self.keys["arrow_up"]
		braking = self.keys["arrow_down"]
		if thrusting:
			rad = math.radians(-self.heading)
			fwd = Vec3(math.sin(rad), math.cos(rad), 0)
			self.velocity += fwd * THRUST_F * dt

		damp = BRAKE if braking else DRAG
		self.velocity *= (damp ** dt)
		if self.velocity.length() > MAX_SPEED:
			self.velocity.normalize()
			self.velocity *= MAX_SPEED

		p = self.ship_pivot.getPos()
		p += self.velocity * dt
		for axis in (0, 1):
			if p[axis] > WORLD_BOUND:
				p[axis] = -WORLD_BOUND
			elif p[axis] < -WORLD_BOUND:
				p[axis] = WORLD_BOUND
		self.ship_pivot.setPos(p)
		self.ship_pivot.setH(-self.heading)
		return Task.cont


if __name__ == "__main__":
	AstroDrift3D().run()
