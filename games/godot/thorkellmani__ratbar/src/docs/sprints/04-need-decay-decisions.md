# Need Decay — Decision Log

Historical decisions from the completed Need Decay sprint. Superseded proposals stay visible with strikethrough. Follow-ups are in the [backlog](../RAT_SIMULATION_BACKLOG.md#behavior-and-tuning); the decisions below preserve the sprint outcome.

- ~~Give selected needs special baseline rules: faster energy decay while working, social decay based on `socialness`, and vice decay based on stress or addiction.~~ All five needs use the same flat-decay mechanism, with independently configurable rates starting at `-5` per game-hour. Job and location modifiers carry state-dependent effects.
- ~~Decay stimulation only during repetitive or unstimulating activity.~~ Stimulation uses flat baseline decay. Repetition is a separate, later feature.
- ~~Couple `vice_satisfaction` decay to stress and addiction.~~ Addiction tracking was removed. Revisit stress coupling after the Stress System exists.
- Baseline decay applies during travel. Location and job effects require the rat to be stationary; job effects additionally require it to be working at an assigned station.
- ~~Use a fixed score-gap threshold to stop switching between near-tied locations.~~ This proposal was replaced by a primary-need commitment proposal, which was also deferred.
- ~~When a rat chooses a location, lock to its highest-urgency active need until that need reaches its `GenerationDefaults` baseline; interrupt immediately if any need crosses `DEAD_BAND_FLOOR`.~~ Positive `pull` does not guarantee that the location improves the need after baseline decay and job effects. Employment pressure can also cause the location to win for reasons unrelated to the chosen need. The rule could keep a rat committed until crisis rather than satisfaction, so it was not implemented.
- Observe whether the current decision schedule causes flicker before designing a general switching rule. Design stopping behavior for each need when its fulfillment activity exists; severity- or personality-adjusted targets and acute crisis behavior remain undecided.
- The live nutrition slide was rechecked after adding decay: Pantry still overtakes Head Chef around `nutrition = -52`. Location and job modifier values remain first-pass tuning.
