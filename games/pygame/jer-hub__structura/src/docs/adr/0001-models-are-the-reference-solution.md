# The game's data structure code decides what is correct

Puzzle files store only a starting state and a goal, such as "delete 7 from this tree". The game's own data structure code works out the Reference Solution: the correct end state and the best sequence of Moves. Expected answers are never written by hand, because the first draft of the plan showed how hand-written answers drift: its sample Puzzle gave two-children deletion hints for 7, which is actually a leaf in that tree. People still write Hints, but only as wording. An automated check in the build fails if any Hint mentions a specific value that disagrees with the Reference Solution.

## Considered Options

- Hand-written expected answers, kept in line by an automated check against the data structure code. Rejected: the same fact would live in two places.
- Hand-written answers checked only by human review. Rejected: the sample Puzzle in the first plan already shows that this fails.
