"""Build the local review report from completed, integrity-checked evidence."""
import html
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'test-results' / 'algorithm-audit'
base = json.loads((OUT / 'report.json').read_text())
diagnostic = json.loads((OUT / 'diagnostic-report.json').read_text())
frozen = json.loads((OUT / 'frozen-report.json').read_text())
integrity = json.loads((OUT / 'integrity.json').read_text())
assert integrity['production_engines_unchanged']
e = html.escape


def pct(x, digits=3):
    return f'{100*x:.{digits}f}%'


def table(headers, rows):
    return '<div class="scroll"><table><thead><tr>' + ''.join(f'<th>{e(str(x))}</th>' for x in headers) + '</tr></thead><tbody>' + ''.join('<tr>' + ''.join(f'<td>{e(str(x))}</td>' for x in row) + '</tr>' for row in rows) + '</tbody></table></div>'


def link(name, label):
    return f'<a href="sigma-derby/test-results/algorithm-audit/{e(name)}">{e(label)}</a>'


hold = frozen['holdout']
summary = hold['excluded_targets']
assert all(m['invalid_finishes'] == 0 for m in base['models'].values())
assert all(m['invalid_finishes'] == 0 for m in diagnostic['models'].values())
assert hold['invalid_finishes'] == 0 and all(m['invalid_finishes'] == 0 for m in frozen['ticks'].values())
sections = [
    '<h1>Horse racing algorithm audit</h1><p class="date">October 23, 2026 | Calculation and testing checkpoint</p>',
    '<div class="outcome"><strong>The current game is not calibrated to the requested probabilities.</strong><p>The isolated candidate improves the individual win rates. Combination probabilities and payout arithmetic must also be resolved before it can replace the playable engine. Neither playable engine was changed in this checkpoint.</p></div>',
    '<h2>What was tested</h2><p>480,000 validation or diagnostic race evaluations, plus 60,000 training evaluations on 10,000 reused training seeds. The timing diagnostic deliberately reuses each seed across its three settings. Training was kept separate from the final 200,000-race holdout. A million or ten million races were unnecessary to detect the current failures.</p>',
    table(['Stage', 'Races', 'Purpose'], [
        ['Original engines and equal-strength control', '150,000', 'Find individual, pair and ordered-pair mismatches'],
        ['Separated-stream diagnostic', '100,000', 'Investigate the equal-strength combination skew'],
        ['Six fixed fitting iterations', '60,000 evaluations / 10,000 seeds', 'Fit individual win rates only; not validation'],
        ['Frozen candidate, fresh holdout', '200,000', 'Check all five wins, ten pairs and twenty ordered pairs'],
        ['Coarse, Standard and Fine timing', '30,000', 'Screen for timing sensitivity; 10,000 shared seeds per setting']]),
    '<h2>Individual horse probabilities</h2><p>The target percentages were fixed before testing. The holdout uses fresh seeds after the candidate strengths were frozen.</p>',
    table(['Horse', 'Target', 'Playable engine', 'Original movement preview', 'Frozen candidate'], [
        [h, pct(hold['wins'][h]['target']), pct(base['models']['legacy']['wins'][h]['observed']),
         pct(base['models']['effort']['wins'][h]['observed']), pct(hold['wins'][h]['observed'])] for h in hold['wins']]),
    f'<p>The candidate holdout has a simultaneous 99% absolute-error bound of plus or minus {100*frozen["registration"]["holdout"]["radius"]:.4f} percentage points across all 35 probability checks. Targets outside the bounds: {summary["wins"]} of 5 individual wins, {summary["pairs"]} of 10 unordered pairs and {summary["ordered"]} of 20 ordered pairs. A target inside a bound is not proof of exact agreement or a completed payback certification.</p>',
    '<h2>Two-horse combinations</h2><p>A pair wins when its two horses occupy first and second in either order. These targets use the existing predeclared Plackett-Luce reference. Matching individual winners alone does not establish matching pairs.</p>',
    table(['Pair', 'Target', 'Playable engine', 'Original preview', 'Frozen candidate', 'Target outside candidate bound'], [
        [p, pct(v['target']), pct(base['models']['legacy']['pairs'][p]['observed']),
         pct(base['models']['effort']['pairs'][p]['observed']), pct(v['observed']), 'Yes' if v['target_excluded'] else 'No']
        for p, v in hold['pairs'].items()]),
    '<details><summary>All twenty ordered first/second checks</summary>' + table(['First, second', 'Target', 'Frozen candidate', '99% simultaneous lower', 'Upper', 'Target excluded'], [
        [p, pct(v['target']), pct(v['observed']), pct(v['low']), pct(v['high']), 'Yes' if v['target_excluded'] else 'No']
        for p, v in hold['ordered'].items()]) + '</details>',
    '<h2>Randomness and a fresh first race</h2><p>The playable game already requests fresh operating-system random bytes on each start. However, its deterministic movement generator reduces the seed to about 31 bits. The preview also derives horse streams by adding fixed offsets, creating related streams. In an equal-strength test, pair 2-4 occurred 12.050% of the time instead of the 10% target. With separately hashed stream seeds, all ten observed pairs ranged from 9.928% to 10.204% over 50,000 fresh races. This is strong evidence of a stream-dependence defect.</p>',
    '<p>The stronger test candidate keeps a full 256-bit seed and derives separate SHA-256 counter streams for scheduling and each horse. Its seed helper combines fresh OS cryptographic entropy with high-resolution time, system time, process id and an optional in-game mouse-activity digest. Time and mouse movement supplement OS entropy; the game must work correctly even if the mouse does not move. Mouse-event collection and the normal-launcher adapter remain to be implemented.</p>',
    '<p>At integration, accept Start and lock wagers first, then create and retain one fresh seed for that race. Do not reseed during the race. Store the exact seed and configuration for controlled replay, without showing a future result to the manager. A repeat winner is still allowed and must not trigger a reroll. No finite random system can guarantee that a winner or seed never repeats; the purpose is to prevent a predictable repeated startup sequence. These tests do not certify resistance to every attack on a locally controlled computer.</p>',
    f'<p>About the observed three consecutive 1-2 combinations: the current playable engine produced that unordered pair in {pct(base["models"]["legacy"]["pairs"]["1-2"]["observed"])} of the sampled races. Using that measured rate and assuming independent races, the estimated chance for that pair in three specified consecutive races is {pct(base["models"]["legacy"]["pair_1_2_three_consecutive_probability_estimate"])}. This is not the chance of seeing any such streak somewhere in a longer session, and it does not require horse 1 to beat horse 2 within the pair. Repetition alone is not evidence of a fixed opening result.</p>',
    '<p>Actual Godot tests passed 5,605 seed/replay checks, including 1,000 fresh-seed calls with no duplicate observed, lossless seed storage, reproducible playback, all five horses once per round, legal consecutive turns across round boundaries, and no rank or gap feedback.</p>',
    '<h2>Close fields and position changes</h2><p>These measurements use 1,000 preselected races per model. They describe races from 5% elapsed time through the second crossing, sampled at 1,001 equally spaced times. A sustained lead change requires at least half a logical step of advantage for 1% of the measured race time. Sampled wire-to-wire does not mean every continuous instant from the starting gate.</p>'
]

competitors = [base['models']['legacy']['competition'], base['models']['effort']['competition'], frozen['competition']]
measures = [('Mean sustained lead changes', 'lead_changes', False), ('Mean pairwise position changes', 'position_changes', False),
            ('Sampled same leader after opening', 'strict_sampled_wire_to_wire', True), ('Sampled same last horse after opening', 'same_last_after_opening', True),
            ('Winner was last at 90% of measured race time', 'winner_last_at_90pct', True), ('Mean field span, percent of lap', 'mean_span_pct', False),
            ('Mean of maximum field span, percent of lap', 'max_span_pct', False)]
sections.append(table(['Measure', 'Playable engine', 'Original preview', 'Frozen candidate'], [
    [label] + [pct(c['means'][key], 1) if probability else f'{c["means"][key]:.3f}' for c in competitors]
    for label, key, probability in measures]))
sections += [
    '<p>These competition metrics are descriptive, not user-approved numerical acceptance thresholds. The model uses each horse\'s own surge, recovery and bounded acceleration. It does not slow a horse because it is leading or boost a horse because it is last. Five horses still move once per independently shuffled round. The finish is determined by actual movement events.</p>',
    '<h2>Timing: the old 10x is now 1 tick, Standard</h2><p>The approved baseline remains exactly 0.005 seconds per round. The future slider should be centered there, with coarser movement to the left and finer movement to the right. The test used 0.05, 0.005 and 0.001 seconds; no slider or shipped timing changed tonight.</p>',
    table(['Horse', 'Target', 'Coarse: 0.05 s', 'Standard: 0.005 s', 'Fine: 0.001 s'], [
        [h, pct(hold['wins'][h]['target'])] + [pct(frozen['ticks'][k]['wins'][h]['observed']) for k in ('coarse', 'standard', 'fine')]
        for h in hold['wins']]),
    f'<p>With the same 10,000 seeds, the winner changed in {frozen["tick_same_seed_winner_changes"]["coarse"]:,} coarse runs and {frozen["tick_same_seed_winner_changes"]["fine"]:,} fine runs compared with Standard. A changed outcome for one seed does not itself prove changed long-run odds. The timing screen has a broad simultaneous bound of plus or minus {100*frozen["registration"]["ticks"]["radius"]:.3f} percentage points, so it cannot certify that a manager-adjustable simulation tick leaves all odds unchanged. Until stronger evidence exists, keep the authoritative simulation fixed and treat display smoothness/performance as a separate control, or validate each movement configuration before enabling it.</p>',
    '<h2>Why every betting style cannot yet match the payback setting</h2><p>At the current 90% setting, integer payout rounding creates unequal expected returns even if every target probability is achieved. The arithmetic below uses the target probabilities, independent of simulation error. Multipliers are total returns including the stake.</p>',
    table(['Pair', 'Current total-return multiplier', 'Expected return if target is met'], [
        [p, str(base['rounding']['payouts'][p])+'x', pct(r)] for p, r in base['rounding']['target_expected_return'].items()]),
    f'<p>For this fixed ten-cell board, equal per-bet return would have to be {pct(diagnostic["fixed_board_equal_rtp"])} because the mutually exclusive pair probabilities sum to one. It cannot simultaneously be exactly 90% with these same fixed integer payouts. More Monte Carlo races will not remove this rounding difference. The payout policy needs a deliberate choice, such as more precise credit payouts or another target-consistent scheme, before all styles can have the same expected return.</p>',
    '<details><summary>Eight fixed example betting portfolios</summary><p>These are arithmetic examples, not runs of the planned virtual-player system. Each listed selection receives one unit.</p>' + table(['Portfolio', 'Return if target probabilities are met'], [[name, pct(v['target_only_rtp'])] for name, v in diagnostic['style_expectations'].items()]) + '</details>',
    '<h2>Coverage and remaining work</h2>',
    table(['Area', 'What this checkpoint establishes', 'Still required'], [
        ['SD playable race', 'Existing engine measured, source unchanged', 'Calibrated replacement and integration tests'],
        ['New movement preview', 'Competition, exact replay and probability mismatches measured', 'Joint individual/pair calibration'],
        ['Live Track / Off-Track TV', 'Shared win/pair targets examined mathematically', 'Modes, broader wager settlement and end-to-end tests are not implemented'],
        ['Exact five-horse order', 'Not validated', 'Continue the authoritative engine until all five actual crossings; current third-fifth are positions at second finish'],
        ['Payback and virtual styles', 'Rounding and example style differences demonstrated', 'Equal-return payout policy, implemented styles and settlement tests'],
        ['Strong fresh seed', 'Test-only helper and full-width streams verified', 'Wire seed lifecycle and in-game mouse digest into normal launchers'],
        ['UI requests', 'Recorded, not changed tonight', 'Larger READY; yellow wager border; larger, flashing enabled START RACE']]),
    '<p>No invalid first/second finish was found in the completed numerical batches. The legacy engine recorded 49 exact first/second time ties, resolved by its existing seeded tie priority. The serial-turn effort batches had no such ties. Remaining horses in each saved order are ranked at second finish, not claimed as actual final placements.</p>',
    '<h2>Method and reproducibility</h2><p>Seeds were frozen before batch outcomes. The six fitting iterations reused a separate 10,000-seed training set; the final strengths were frozen before drawing 200,000 new holdout seeds. Complete row identities, seeds, counts, finite values and source hashes were checked. No winner selection, rejected-race sampling, streak breaking or wager-based tuning was used.</p>',
    '<p>The fast C# simulator was checked against actual Godot engines on 296 fixtures across four oracle sets, including playback, event counts and finish order. It passed 1,487,400 comparisons with numerical differences below 1e-8. The original core suite passed 149,103 assertions, the effort suite passed 20,723 and the new seed suite passed 5,605. Metrics were separately checked against the existing Godot measurement harness.</p>',
    '<p>For each predeclared family of m probability checks, the bound is sqrt(log(2m/0.01)/(2n)). It follows from the two-sided Hoeffding inequality and the union bound under independent random race seeds. The baseline family has 105 endpoints at 50,000 races per scenario; the stream diagnostic has 70 at 50,000; the final holdout has 35 at 200,000; timing has 105 at 10,000 per setting. Each family has its own 99% coverage statement. That is not one joint 99% claim across all adaptive investigations. Conservative absolute bounds can be especially wide for rare, high-payout bets. No payout tolerance was declared, so this is a diagnostic audit, not equivalence certification.</p>',
    '<p>Method references: <a href="https://www.tandfonline.com/doi/abs/10.1080/01621459.1963.10500830">Hoeffding, Probability Inequalities for Sums of Bounded Random Variables</a>; <a href="https://itl.nist.gov/div898/handbook/prc/section4/prc473.htm">NIST simultaneous-interval coverage</a>; <a href="https://docs.godotengine.org/en/stable/classes/class_crypto.html#class-crypto-method-generate-random-bytes">Godot cryptographic random bytes</a>.</p>',
    '<p>Detailed evidence: ' + ', '.join([link('report.json', 'baseline'), link('diagnostic-report.json', 'stream diagnosis'), link('frozen-report.json', 'frozen holdout and timing'), link('integrity.json', 'integrity and unchanged engines')]) + '. Reproduction instructions are in <a href="sigma-derby/docs/ALGORITHM_AUDIT.md">the audit notes</a>. These are local links within this output folder.</p>',
    '<p class="note">This checkpoint contains test tools and evidence. It is not a new playable release, and neither launcher loads the candidate automatically.</p>'
]
sections += [
    '<h2>Independent review</h2><p>A fresh read-only review found no Important or Critical defect in this testing checkpoint. It independently checked the arithmetic, production hashes and complete unique coverage of all four oracle datasets. Two minor follow-ups remain: stronger duplicate-ID/sample rejection in the reusable oracle guard, and explicit PowerShell version guidance. The tools were tested with PowerShell 7.6.7; Windows PowerShell 5.1 lacks the required hashing API.</p>',
    '<p>This audit covers the first fixed probability scenario and the current 90% payout board, not all future randomized cards or payback settings. <a href="sigma-derby/docs/ALGORITHM_AUDIT_REVIEW.md">Review findings and scope decisions</a> preserve the details. Static content, links and archive integrity passed; the browser policy blocked local file URLs, so rendered appearance was not visually checked.</p>'
]

document = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Horse Racing Algorithm Audit</title><style>
body{font-family:"Aptos Display",Aptos,Arial,sans-serif;font-size:12pt;line-height:1.45;color:#182534;background:#f5f7f9;margin:0}main{max-width:1120px;margin:24px auto;padding:28px;background:white}h1{font-size:26pt;margin:0}h2{font-size:18pt;margin-top:30px}p{margin:0 0 6pt}.date,.note{color:#4f5e6c}.outcome{background:#fff4d3;border-left:5px solid #b98000;padding:16px;margin:20px 0}.scroll{overflow:auto;margin:14px 0 20px}table{border-collapse:collapse;width:100%;font-size:11pt}th,td{padding:9px 11px;border-bottom:1px solid #d4dce3;text-align:left}th{background:#e9eff4}tbody tr:nth-child(even){background:#f8fafb}details{margin:16px 0}summary{cursor:pointer;font-weight:bold;padding:8px 0}a{color:#075dab}@media(max-width:600px){main{margin:0;padding:16px}}@media print{body{background:white}main{margin:0;padding:0}details{display:block}.outcome{break-inside:avoid}}
</style><main>''' + '\n'.join(sections) + '</main></html>'
(ROOT.parent / 'ALGORITHM_TEST_REPORT.html').write_text(document, encoding='utf-8')
print(ROOT.parent / 'ALGORITHM_TEST_REPORT.html')
