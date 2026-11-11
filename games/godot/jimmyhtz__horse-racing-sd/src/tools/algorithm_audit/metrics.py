"""Shared measurements, cross-checked against movement_compare.gd."""
from statistics import mean

def metrics(samples,winner):
    # Reuse movement_compare.gd definitions; add strict sampled leader control.
    leader=candidate=initial_leader=initial_last=None
    candidate_since=changes=overtakes=0
    stayed_last=strict_lead=True
    pair_signs={}; spans=[]; first_gaps=[]; last_gaps=[]
    for index in range(50,1001):
        pos=samples[index]
        order=sorted(range(5),key=lambda h:-pos[h])
        spans.append((pos[order[0]]-pos[order[4]])/10)
        first_gaps.append((pos[order[0]]-pos[order[1]])/10)
        last_gaps.append((pos[order[3]]-pos[order[4]])/10)
        if initial_last is None: initial_last=order[4]
        stayed_last &= order[4]==initial_last
        if leader is None: leader=initial_leader=order[0]
        strict_lead &= order[0]==initial_leader
        if order[0]!=leader and pos[order[0]]-pos[order[1]]>=.5:
            if candidate!=order[0]: candidate=order[0]; candidate_since=index
            elif index-candidate_since>=10: changes+=1; leader=candidate; candidate=None
        else: candidate=None
        for a in range(5):
            for b in range(a+1,5):
                gap=pos[a]-pos[b]
                if abs(gap)<.5: continue
                sign=1 if gap>0 else -1
                if (a,b) in pair_signs and pair_signs[a,b]!=sign: overtakes+=1
                pair_signs[a,b]=sign
    return dict(lead_changes=changes,position_changes=overtakes,
                wire_to_wire_after_opening=changes==0 and winner==initial_leader,
                strict_sampled_wire_to_wire=strict_lead and winner==initial_leader,
                same_last_after_opening=stayed_last,
                winner_last_at_90pct=samples[900][winner]==min(samples[900]),
                mean_span_pct=mean(spans),max_span_pct=max(spans),
                maximum_leader_gap_pct=max(first_gaps),maximum_last_gap_pct=max(last_gaps),
                time_fraction_span_under_5pct=mean(s<=5 for s in spans))
