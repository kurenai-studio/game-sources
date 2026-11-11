"""Independent conditional-state calibration, not an acceptance race sample."""
from pathlib import Path
import json,sys,math,hashlib
from fractions import Fraction
import numpy as np
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'tools/payback_v2'))
from math_model import finish_pmf
catalog=json.loads((root/'data/payback_v1.json').read_text());D=catalog['distance_units'];N=8192
rng=np.random.default_rng(9186354972)
def binomial(n,p):
    mode=int((n+1)*p);w=np.empty(n+1);w[mode]=1
    k=np.arange(mode+1,n+1,dtype=float)
    w[mode+1:]=np.cumprod((n-k+1)/k*p/(1-p))
    k=np.arange(mode,0,-1,dtype=float)
    w[:mode]=np.cumprod(k/(n-k+1)*(1-p)/p)[::-1]
    w/=w.sum();return w,np.cumsum(w)
components=[]
for c,component in enumerate(catalog['components']):
    ps=[component['high_threshold']/2**32]*2+[component['low_threshold']/2**32]*3
    pmfs={}
    for p in set(ps):pmfs[p]=np.asarray(finish_pmf(D,Fraction(p),precision=60))
    finish=np.column_stack([rng.choice(D+1,N,p=pmfs[p]) for p in ps])
    slots=np.argsort(np.argsort(rng.random((N,5)),axis=1),axis=1)
    order=np.argsort(finish*5+slots,axis=1)
    second=order[:,1];rounds=finish[np.arange(N),second];second_slot=slots[np.arange(N),second]
    rows=[];states=np.zeros((N,5),dtype=int)
    remaining=np.ones((N,5),dtype=bool);remaining[np.arange(N),order[:,0]]=False;remaining[np.arange(N),second]=False
    for h,p in enumerate(ps):
        for r in np.unique(rounds):
            mask=(rounds==r)&remaining[:,h];ids=np.flatnonzero(mask)
            if not len(ids):continue
            later=ids[finish[ids,h]>r]
            if len(later):
                w,cdf=binomial(int(r),p);cut=D-int(r)-1
                assert cut>=0 and cdf[cut]>0
                k=np.searchsorted(cdf,rng.random(len(later))*cdf[cut])
                progress=r+k
                waiting=slots[later,h]>second_slot[later]
                progress-=waiting*(1+(rng.random(len(later))<k/r))
                states[later,h]=progress
            crossing=ids[finish[ids,h]==r]
            if len(crossing):
                assert np.all(slots[crossing,h]>second_slot[crossing])
                w,_=binomial(int(r)-1,p)
                a=w[D-int(r)];bb=p*w[D-int(r)-1]
                states[crossing,h]=D-2+(rng.random(len(crossing))<a/(a+bb))
    assert np.all(states[remaining]<D) and np.all(states[remaining]>0)
    phases=rng.integers(0,2**32,size=(N,3),dtype=np.uint64)
    for i in range(N):rows.append([int(v) for v in states[i,remaining[i]]]+[int(v) for v in phases[i]])
    components.append(rows)
    gaps=D-states[remaining].reshape(N,3).max(axis=1)
    print(json.dumps({'component':c,'samples':N,'raw_gap_percentiles':np.quantile(gaps,[.1,.2,.3,.5]).tolist()}),flush=True)
out={'schema':1,'method':'independent-conditional-first-passage-states-v1','samples_per_component':N,'distance':D,
     'columns':['effort_a','effort_b','effort_c','phase_a_uint32','phase_b_uint32','phase_c_uint32'],
     'trajectory_version':'full-course-positive-stride-v1','component_thresholds':[{k:c[k] for k in ['high_threshold','low_threshold']} for c in catalog['components']],
     'kernel_sha256':hashlib.sha256((root/'data/payback_v1.json').read_bytes()).hexdigest(),'components':components}
(root/'data/replay_reference_v2.json').write_text(json.dumps(out,separators=(',',':'))+'\n')
print('REFERENCE21 complete',flush=True)
