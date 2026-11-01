# Hamurapi Technical Whitepaper

**v1.0.0** | October 2026

Hamurabi is one of the first computer games anyone played. Doug Dyment wrote it in 1968, David Ahl put it in *101 BASIC Computer Games* in 1973, and a generation learned what a variable was by typing it in. It is a handful of numbers, a few dice rolls, and an honest lesson about how thin the line is between a full barn and a riot. This project rebuilds it as a game you can watch, on the web, Mac, iPhone and in a terminal, and asks a question the original never did: how well can a ruler actually play?

## The rules

You start with 100 people, 1,000 acres and 2,800 bushels. Every year you give three orders: acres to buy or sell, bushels to feed, and acres to plant.

A person eats 20 bushels a year and can farm 10 acres. Planting costs one bushel of seed an acre. Land trades between 17 and 26 bushels an acre, a new price each year. Then the year plays out. The harvest gives 1 to 5 bushels an acre. Four years in ten, rats eat a quarter or half of what is in the barn. Anyone you did not feed dies, and if that is more than 45 percent of the city, you are thrown out on the spot. If nobody starved, new people arrive, more of them when the city is rich. Then, about one year in seven, a plague kills half the city.

After ten years you are graded on two numbers: the average share of people who starved each year, and the acres each person has. An A+ needs starvation under 3 percent and at least 10 acres a head. Those limits are the 1968 ones. The letters are ours.

## Why it's hard

Run the numbers on one person. They farm 10 acres, which costs 10 bushels of seed and gives 30 in an average year. They eat 20. Net: zero. The city only breaks even on an average harvest, and the rats take about an eighth of the barn every year on top of that. Left alone, the barn shrinks.

Worse, success is punished. A well-fed city draws new people, and every new person lowers the acres each one has, which is half your grade. The city you are building grows away from the score you are chasing.

## One seed, one game, everywhere

The rules are written three times: Python for the terminal, Swift for the app, JavaScript for the web. Three copies drift unless something holds them together.

What holds them is the dice. All three use SplitMix64, and all three turn its output into rolls the same way: a remainder for a whole number, the top 53 bits for a chance. No port uses its language's own random functions, because those differ and change between versions. So seed 42 is the same ten years in every version, on every device.

Each port can play 200 robot games and add up the results into one number: 639940. A second number, 390695, covers 120 story games across all three difficulty levels. If any port changes a rule, an order of dice, or a rounding, its number moves and the check fails. Today's game depends on this: everyone playing on the same day gets the same seed, whether they are in the app or the browser.

## How the robot plays

The robot gives its orders through the same `check` and `step` a person uses, with no look at future dice. It follows four rules.

It feeds everyone but one person, once land per head drops under a line. One hungry mouth a year costs about 1 percent on the starvation score, well inside the 3 percent limit, and it shuts the gates, because new people only come when nobody starved.

It always sets aside a full planting before it buys anything, and when it is short it sells only the land it needs to feed and plant.

It buys land only when land is cheap, and then only a slice of the spare grain, keeping the rest against the rats.

In the last year it plants nothing, because that harvest comes in after the grade, and turns every spare bushel into land.

The line, the price cap and the slice are three knobs. `python3 ruler.py --sweep` tries combinations over 1,000 games and keeps the best: 16 acres a head, buy at 19 or less, spend a sixth of the spare grain.

## Results

Over 1,000 games the robot earns an A+ in 878, a B in 54, a C in 20 and an F in 48. The losses are runs of bad luck. In seed 18 the fields give one bushel an acre in six years out of ten. No orders feed a city through that, because the grain never grows.

## What difficulty changes, and what it must not

The story has three levels. A test caught the first design being backwards: with more plague on Hard, the robot scored better on Hard than on Easy, because plague thins the city and a thin city has more land a head. So the levels move starting grain, starting land, rats, and how many deaths get you thrown out. Plague is the same at every level.

## The city is code

Every sprite is a small grid of letters in `art/build.py`. One pass shades them, light from the top left leaning warm and shadow leaning cool, and wraps each in an outline taken from its own colour. The music and the ten sounds are sine waves and noise from `art/make_audio.py`. The story is one JSON file both the app and the web game read. Nothing is drawn by hand, recorded or copied.

MIT License. Copyright 2026 Joshua Trommel. Based on Hamurabi by Doug Dyment, 1968.
