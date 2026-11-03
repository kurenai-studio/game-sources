/* ══════════════ 13 · wiring the world ══════════════ */
world.register(new ClockSystem(world));
world.register(new RoutineSystem(world));
world.register(new PathSystem(world));
world.register(new GrazeSystem(world));
world.register(new SentrySystem(world));
world.register(new FlightSystem(world));
world.register(new CartSystem(world));
world.register(new LabourSystem(world));
world.register(new GaitSystem(world));
world.register(new SyncSystem(world));
world.register(new WindSystem(world));
world.register(new HearthSystem(world));
world.register(new SkySystem(world));
function retask(){ world.singletons.clock.retask=true; }

