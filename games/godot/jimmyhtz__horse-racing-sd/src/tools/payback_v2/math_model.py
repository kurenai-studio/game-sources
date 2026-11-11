"""Offline probabilities derived from shuffled positive 1-or-2-unit movement.

This is a candidate calculation, not an installed game engine. No Monte Carlo
frequency is used as a target. Decimal recurrence avoids subtracting huge
factorial logarithms or subtracting nearly equal cumulative probabilities.
"""
import itertools
import math
from decimal import Decimal, localcontext
from fractions import Fraction

PAIRS = list(itertools.combinations(range(5), 2))
RETURN_TOLERANCE = Fraction(1, 1_000_000)  # 0.0001 percentage points


def finish_pmf(distance, probability, precision=60):
    if type(distance) is not int or distance < 2 or not 0 < probability < 1:
        raise ValueError('Positive integer distance and nondegenerate step probability required')
    p_fraction = probability if isinstance(probability, Fraction) else Fraction(str(probability))
    with localcontext() as context:
        context.prec = precision
        p = Decimal(p_fraction.numerator) / Decimal(p_fraction.denominator)
        q = 1-p
        start = distance//2 + 1
        anchor = max(start, min(distance, round(distance/(1+float(p)))))
        k = distance-anchor
        term = Decimal(math.comb(anchor-1,k))*p**k*q**(anchor-1-k)
        values = [Decimal(0)]*(distance+1)

        def set_value(r, t):
            # Crossing from D-1 with either step, or from D-2 with a double step.
            values[r] = t*(1 + Decimal(distance-r)*q/Decimal(2*r-distance))

        set_value(anchor, term)
        t = term
        for r in range(anchor, distance):
            t *= Decimal(r*(distance-r))*q*q/(Decimal((2*r-distance+1)*(2*r-distance))*p)
            set_value(r+1,t)
        t = term
        for r in range(anchor-1, start-1, -1):
            t *= Decimal((2*r-distance+1)*(2*r-distance))*p/(Decimal(r*(distance-r))*q*q)
            set_value(r,t)
        if distance % 2 == 0:
            values[distance//2] = p**(distance//2)
        if abs(sum(values)-1) > Decimal('1e-35'):
            raise ArithmeticError('First-passage probability does not normalize')
        return [float(v) for v in values]


def finish_probabilities(distributions):
    if len(distributions) != 5 or len({len(d) for d in distributions}) != 1:
        raise ValueError('Exactly five distributions on one round support required')
    for d in distributions:
        if any(not math.isfinite(v) or v < 0 for v in d) or abs(math.fsum(d)-1)>1e-12:
            raise ValueError('Invalid finishing-round distribution')
    # S(r) is accumulated backwards to avoid cancellation in rare tails.
    survival = []
    for d in distributions:
        s = [0.0]*len(d)
        for r in range(len(d)-2,-1,-1):
            s[r] = s[r+1]+d[r+1]
        survival.append(s)
    ordered = [[0.0]*5 for _ in range(5)]
    previous = [0.0]*5
    for r in range(len(distributions[0])):
        f = [d[r] for d in distributions]
        for i,j in PAIRS:
            coefficients = [1.0]
            for k in range(5):
                if k in (i,j):
                    continue
                new = [0.0]*(len(coefficients)+1)
                for t,c in enumerate(coefficients):
                    new[t] += c*survival[k][r]
                    new[t+1] += c*f[k]
                coefficients = new
            # Among t simultaneous crossers, the shuffled turn is uniform.
            single = sum(c/(t+1) for t,c in enumerate(coefficients))
            joint = sum(c/((t+1)*(t+2)) for t,c in enumerate(coefficients))
            ordered[i][j] += previous[i]*f[j]*single + f[i]*f[j]*joint
            ordered[j][i] += previous[j]*f[i]*single + f[i]*f[j]*joint
        previous = [a+b for a,b in zip(previous,f)]
    pairs = [ordered[i][j]+ordered[j][i] for i,j in PAIRS]
    if abs(sum(pairs)-1)>1e-11:
        raise ArithmeticError('Joint finishing probability does not normalize')
    return {'ordered':ordered, 'pairs':pairs, 'wins':[sum(row) for row in ordered]}


def card_contract(percent, payoffs):
    if type(percent) is not int or not 70 <= percent <= 200:
        raise ValueError('Unsupported payout percentage')
    if len(payoffs)!=10 or any(type(m) is not int or not 2<=m<=200 for m in payoffs):
        raise ValueError('Ten whole-credit payoffs between 2 and 200 required')
    actual = 1/sum(Fraction(1,m) for m in payoffs)
    if abs(actual-Fraction(percent,100)) > RETURN_TOLERANCE:
        raise ValueError('Integer payoff card misses the requested return')
    return {'requested_percent':percent, 'payoffs':list(payoffs),
            'exact_return':actual, 'pair_probabilities':[actual/m for m in payoffs]}


def public_card(contract):
    return {'payoffs':list(contract['payoffs']),
            'payout_semantics':'total return including original stake'}


def solve_linear(matrix, rhs):
    a = [list(row)+[float(value)] for row,value in zip(matrix,rhs)]
    n = len(a)
    for i in range(n):
        k = max(range(i,n),key=lambda k:abs(a[k][i]))
        if abs(a[k][i]) < 1e-12:
            raise ValueError('Movement profiles cannot represent this card')
        a[i],a[k] = a[k],a[i]
        divisor = a[i][i]
        a[i] = [v/divisor for v in a[i]]
        for j in range(n):
            if j != i:
                factor = a[j][i]
                a[j] = [v-factor*w for v,w in zip(a[j],a[i])]
    return [row[-1] for row in a]


def fit_profiles(component, contract):
    """Select a distribution of pace parameters, never a finishing order.

    Each profile has two horses with the high step probability and three with
    the low one. All five still make fresh independent movement draws. A profile
    is not a winning pair: any horse can win or lose in every profile.
    """
    orders = []
    for high in PAIRS:
        labels = list(high)+[h for h in range(5) if h not in high]
        reverse = [labels.index(h) for h in range(5)]
        orders.append([[component['ordered'][reverse[i]][reverse[j]] for j in range(5)] for i in range(5)])
    matrix = [[o[i][j]+o[j][i] for o in orders] for i,j in PAIRS]
    weights = solve_linear(matrix,contract['pair_probabilities'])
    if min(weights)<-1e-10 or abs(sum(weights)-1)>1e-10:
        raise ValueError('No nonnegative mixture for these movement parameters')
    weights = [max(0,w) for w in weights]
    total = sum(weights)
    scaled = [w/total*2**48 for w in weights]
    units = [math.floor(v) for v in scaled]
    for k in sorted(range(10),key=lambda k:scaled[k]-units[k], reverse=True)[:2**48-sum(units)]:
        units[k] += 1
    ordered = [[math.fsum(units[k]/2**48*orders[k][i][j] for k in range(10)) for j in range(5)] for i in range(5)]
    pairs = [ordered[i][j]+ordered[j][i] for i,j in PAIRS]
    error = max(abs(p*m-contract['requested_percent']/100) for p,m in zip(pairs,contract['payoffs']))
    if error>float(RETURN_TOLERANCE):
        raise ValueError('Quantized movement mixture misses the payback tolerance')
    return {'profile_units':units,'pairs':pairs,'ordered':ordered,
            'wins':[sum(row) for row in ordered],'max_return_error':error}
