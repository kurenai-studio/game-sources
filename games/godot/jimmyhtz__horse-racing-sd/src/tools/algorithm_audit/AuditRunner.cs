// Offline measurement replica only. Production remains in the Godot engines.
using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.Text;
using System.Security.Cryptography;

public static class DerbyAudit {
    sealed class Rng {
        long state;
        string prefix;
        long counter;
        byte[] block;
        int offset=32;
        public Rng(long seed) { state = ((seed % 2147483646L)+2147483646L)%2147483646L+1; }
        public Rng(string master,string domain) { prefix="DerbyAudit:v3:"+master+":"+domain+":"; }
        long Next() { return state = (state*48271L)%2147483647L; }
        long Raw() {
            if(prefix==null) return Next()-1;
            if(offset==32) { block=SHA256.HashData(Encoding.UTF8.GetBytes(prefix+(counter++))); offset=0; }
            long value=(long)block[offset]+((long)block[offset+1]<<8)+((long)block[offset+2]<<16)+((long)block[offset+3]<<24);
            offset+=4; return value;
        }
        public double Unit() { return (double)Raw()/(prefix==null?2147483646.0:4294967296.0); }
        public int Index(int count) {
            long range=prefix==null?2147483646L:4294967296L,limit=range-range%count, draw=Raw();
            while(draw>=limit) draw=Raw();
            return (int)(draw%count);
        }
        public int[] Permute() {
            int[] a={0,1,2,3,4};
            for(int i=4;i>0;i--) { int j=Index(i+1), t=a[i]; a[i]=a[j]; a[j]=t; }
            return a;
        }
    }
    sealed class Result {
        public int First,Second,Events;
        public double T1,T2;
        public int[] Order;
        public double[] Pos,Speed;
        public List<double[]> Trace;
        public double Step;
    }
    static double Clamp(double x,double lo,double hi) { return Math.Min(Math.Max(x,lo),hi); }
    static double Move(double from,double to,double amount) { return Math.Abs(to-from)<=amount ? to : from+Math.Sign(to-from)*amount; }
    static long DomainSeed(long seed,string domain) {
        return DomainHash("DerbyAudit:v1:"+seed+":"+domain);
    }
    static long DomainHash(string text) {
        using(var sha=SHA256.Create()) {
            byte[] bytes=sha.ComputeHash(Encoding.UTF8.GetBytes(text));
            return (long)bytes[0]+((long)bytes[1]<<8)+((long)bytes[2]<<16)+((long)bytes[3]<<24);
        }
    }
    static Result Seal(int first,int second,int events,double t1,double t2,double[] pos,double[] speed,int[] tie,List<double[]> trace,double step) {
        var rest=Enumerable.Range(0,5).Where(h=>h!=first&&h!=second).ToArray();
        Array.Sort(rest,(a,b)=>pos[a]==pos[b] ? Array.IndexOf(tie,a).CompareTo(Array.IndexOf(tie,b)) : pos[b].CompareTo(pos[a]));
        return new Result {First=first,Second=second,Events=events,T1=t1,T2=t2,
            Order=new[]{first,second}.Concat(rest).ToArray(),Pos=pos,Speed=speed,Trace=trace,Step=step};
    }
    static Result Legacy(long seed,bool record) {
        var rng=new Rng(seed); int[] tie=rng.Permute(),level={2,2,2,2,2};
        double[] pos=new double[5],speed=new double[5],bias={.54,.52,.50,.48,.44};
        var trace=record ? new List<double[]> { (double[])pos.Clone() } : null;
        int first=-1,events=0; double clock=0,t1=0;
        var cross=new List<KeyValuePair<int,double>>(5);
        for(;;) {
            int selected=rng.Index(5);
            if(rng.Unit()<.65) level[selected]=Math.Min(4,Math.Max(0,level[selected]+(rng.Unit()<bias[selected]?1:-1)));
            cross.Clear();
            for(int h=0;h<5;h++) {
                speed[h]=.5+.5*level[h];
                if(pos[h]<1000&&pos[h]+speed[h]>=1000) cross.Add(new KeyValuePair<int,double>(h,clock+(1000-pos[h])/speed[h]));
            }
            cross.Sort((a,b)=>a.Value==b.Value?Array.IndexOf(tie,a.Key).CompareTo(Array.IndexOf(tie,b.Key)):a.Value.CompareTo(b.Value));
            int second=-1; double elapsed=1,t2=0;
            foreach(var item in cross) {
                if(first<0) { first=item.Key; t1=item.Value; }
                else { second=item.Key; t2=item.Value; elapsed=t2-clock; break; }
            }
            for(int h=0;h<5;h++) pos[h]+=speed[h]*elapsed;
            clock+=elapsed; events++;
            if(record) trace.Add((double[])pos.Clone());
            if(second>=0) return Seal(first,second,events,t1,t2,pos,speed,tie,trace,1);
            if(events>300000) throw new Exception("Legacy event bound");
        }
    }
    static Result Effort(long seed,string profile,bool record,string master=null,double tick=0) {
        double finish=1000,basis=30,spread=.12,accel=.08,dt=.005,surge=4,recovery=3.5,phaseMin=1,phaseMax=3;
        double[] strength={.10,.05,0,-.05,-.10};
        if(profile=="equal"||profile=="mixed_equal"||profile=="super_equal") strength=new double[5];
        if(profile.StartsWith("super_fit:")) {
            var parts=profile.Substring(10).Split(';');
            if(parts.Length!=5) throw new Exception("Five fitted strengths required");
            strength=parts.Select(v=>double.Parse(v,CultureInfo.InvariantCulture)).ToArray();
            if(strength.Any(v=>double.IsNaN(v)||Math.Abs(v)>.3)) throw new Exception("Invalid fitted strength");
        }
        if(profile.Contains("_coarse")) dt=.05;
        if(profile.Contains("_fine")) dt=.001;
        if(tick>0) dt=tick;
        if(profile=="constant") { basis=10; spread=0; dt=.01; finish=.15; }
        if(profile=="edge") { spread=.4; accel=1; dt=.001; finish=100; strength=new[]{.3,-.3,.3,-.3,0}; }
        bool mixed=profile.StartsWith("mixed"),super=profile.StartsWith("super");
        var scheduler=super?new Rng(master,"scheduler"):new Rng(mixed?DomainSeed(seed,"scheduler"):seed); var streams=new Rng[5];
        double[] pos=new double[5],speed=new double[5],effort=new double[5],target=new double[5],phase=new double[5];
        for(int h=0;h<5;h++) { streams[h]=super?new Rng(master,"horse:"+h):new Rng(mixed?DomainSeed(seed,"horse:"+h):seed+7919L*(h+1)); speed[h]=target[h]=basis; effort[h]=.45+.4*streams[h].Unit(); }
        var trace=record ? new List<double[]> { (double[])pos.Clone() } : null;
        int slot=5,first=-1,events=0; int[] order=null;
        double clock=0,t1=0,turn=dt/5;
        for(;;) {
            if(slot==5) { order=scheduler.Permute(); slot=0; }
            int h=order[slot];
            double relative=(speed[h]/basis-1)/Math.Max(spread,.000001);
            if(relative>0) effort[h]=Math.Max(0,effort[h]-relative*dt/surge);
            else if(relative<0) effort[h]=Math.Min(1,effort[h]-relative*dt/recovery);
            else effort[h]=Math.Min(1,effort[h]+.02*dt);
            phase[h]-=dt;
            if(phase[h]<=0) {
                double probability=Clamp(.12+.70*effort[h]+strength[h],.02,.95);
                double draw=streams[h].Unit(),amplitude=spread*(.4+.6*streams[h].Unit());
                target[h]=draw<probability ? basis*(1+amplitude) : (draw<probability+(1-probability)*.75 ? basis*(1-amplitude) : basis);
                phase[h]=phaseMin+(phaseMax-phaseMin)*streams[h].Unit();
            }
            if(effort[h]<=.01&&target[h]>basis) target[h]=basis*(1-.5*spread);
            speed[h]=Move(speed[h],target[h],basis*accel*dt);
            double distance=speed[h]*dt,fraction=1,t2=0; int second=-1;
            if(pos[h]<finish&&pos[h]+distance>=finish) {
                double crossing=(finish-pos[h])/distance,time=clock+turn*crossing;
                if(first<0) { first=h; t1=time; }
                else { second=h; t2=time; fraction=crossing; }
            }
            pos[h]+=distance*fraction; clock+=turn*fraction; slot++; events++;
            if(record) trace.Add((double[])pos.Clone());
            if(second>=0) return Seal(first,second,events,t1,t2,pos,speed,order,trace,turn);
            if(events>300000) throw new Exception("Effort event bound");
        }
    }
    static string Num(double x) { return x.ToString("R",CultureInfo.InvariantCulture); }
    public static void Run(string input,string output,string samples) {
        CultureInfo.CurrentCulture=CultureInfo.InvariantCulture;
        var watch=Stopwatch.StartNew(); int count=0;
        using(var writer=new StreamWriter(output))
        using(var sampleWriter=new StreamWriter(samples)) {
            writer.WriteLine("id,profile,seed,first,second,events,t1,t2,o1,o2,o3,o4,o5,p1,p2,p3,p4,p5,v1,v2,v3,v4,v5");
            sampleWriter.WriteLine("id,index,p1,p2,p3,p4,p5");
            foreach(string line in File.ReadLines(input)) {
                var a=line.Split(','); bool record=a[3]=="1"; long seed=a[1].StartsWith("super")?0:long.Parse(a[2]);
                var result=a[1]=="legacy"?Legacy(seed,record):Effort(seed,a[1],record,a[2],a.Length>4?double.Parse(a[4]):0);
                writer.WriteLine(string.Join(",",new[]{a[0],a[1],a[2],result.First.ToString(),result.Second.ToString(),result.Events.ToString(),Num(result.T1),Num(result.T2)})+","+
                    string.Join(",",result.Order)+","+string.Join(",",result.Pos.Select(Num))+","+string.Join(",",result.Speed.Select(Num)));
                if(record) for(int j=0;j<=1000;j++) {
                    double time=result.T2*j/1000.0;
                    double[] positions=new double[5];
                    if(time>=result.T2) positions=result.Pos;
                    else if(time<=0) positions=result.Trace[0];
                    else {
                        int index=Math.Min((int)Math.Floor(time/result.Step),result.Trace.Count-2);
                        double start=index*result.Step,end=Math.Min((index+1)*result.Step,result.T2),alpha=Clamp((time-start)/(end-start),0,1);
                        for(int h=0;h<5;h++) positions[h]=result.Trace[index][h]+(result.Trace[index+1][h]-result.Trace[index][h])*alpha;
                    }
                    sampleWriter.WriteLine(a[0]+","+j+","+string.Join(",",positions.Select(Num)));
                }
                count++;
                if(count%1000==0) { writer.Flush(); sampleWriter.Flush(); Console.WriteLine("AUDIT "+count+" races, "+watch.Elapsed.TotalSeconds.ToString("F1")+" seconds"); }
            }
        }
        Console.WriteLine("AUDIT COMPLETE "+count+" races, "+watch.Elapsed.TotalSeconds.ToString("F1")+" seconds");
    }
    public static void Fit(string seedFile,string output) {
        CultureInfo.CurrentCulture=CultureInfo.InvariantCulture;
        string[] seeds=File.ReadAllLines(seedFile);
        if(seeds.Length!=10000) throw new Exception("Use the frozen 10,000-seed training set");
        double[] strengths={.1,.05,0,-.05,-.1},targets={.35,.27,.20,.13,.05};
        using(var writer=new StreamWriter(output)) {
            writer.WriteLine("iteration,s1,s2,s3,s4,s5,w1,w2,w3,w4,w5");
            for(int iteration=0;iteration<6;iteration++) {
                string profile="super_fit:"+string.Join(";",strengths.Select(Num));
                int[] wins=new int[5];
                foreach(string master in seeds) wins[Effort(0,profile,false,master).First]++;
                writer.WriteLine(iteration+","+string.Join(",",strengths.Select(Num))+","+string.Join(",",wins)); writer.Flush();
                Console.WriteLine("FIT "+iteration+" wins "+string.Join(",",wins));
                if(iteration==5) break;
                // Fixed damped log-ratio updates, all declared before the training run.
                for(int h=0;h<5;h++) strengths[h]+=.7*Math.Log(targets[h]/Math.Max(.0001,(double)wins[h]/seeds.Length))/8.0;
                double center=strengths.Average();
                for(int h=0;h<5;h++) strengths[h]=Clamp(strengths[h]-center,-.3,.3);
            }
        }
    }
}
