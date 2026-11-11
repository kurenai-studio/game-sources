using System;
using System.IO;
using System.Linq;
using System.Text;
using System.Security.Cryptography;
using System.Buffers.Text;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;

// Independent offline implementation. Actual Godot parity is mandatory before use.
public static class PaybackCandidateRunner {
    sealed class Stream {
        readonly byte[] input=new byte[180], block=new byte[32];
        readonly int prefixLength;
        long counter; int offset=32;
        public Stream(string seed,string domain) {
            prefixLength=Encoding.UTF8.GetBytes("DerbyAudit:v3:"+seed+":"+domain+":",input);
        }
        public long Raw() {
            if(offset==32) {
                Utf8Formatter.TryFormat(counter++,input.AsSpan(prefixLength),out int written);
                SHA256.HashData(input.AsSpan(0,prefixLength+written),block);
                offset=0;
            }
            long value=(long)block[offset]+((long)block[offset+1]<<8)+((long)block[offset+2]<<16)+((long)block[offset+3]<<24);
            offset+=4; return value;
        }
        public int Index(int n) {
            long limit=4294967296L-4294967296L%n,draw=Raw();
            while(draw>=limit) draw=Raw();
            return (int)(draw%n);
        }
        public void Shuffle(int[] order) {
            for(int i=0;i<5;i++) order[i]=i;
            for(int i=4;i>0;i--) { int j=Index(i+1),temp=order[i]; order[i]=order[j]; order[j]=temp; }
        }
    }
    static readonly int[,] Pairs={{0,1},{0,2},{0,3},{0,4},{1,2},{1,3},{1,4},{2,3},{2,4},{3,4}};
    sealed class Configuration { public long High,Low; public long[] Mass; }
    sealed class Result {
        public int Profile,Events,Rounds;
        public int[] Order=new int[5];
        public double[] Times=new double[5];
        public int[] Trace;
    }
    static Result Race(string seed,Configuration c,bool record) {
        var r=new Result();
        var choice=new Stream(seed,"payback-v1:parameters");
        long draw=(choice.Raw()<<16)|(choice.Raw()&65535),sum=0;
        r.Profile=-1;
        for(int i=0;i<10;i++) { sum+=c.Mass[i]; if(r.Profile<0 && draw<sum) r.Profile=i; }
        if(sum!=281474976710656L || r.Profile<0) throw new Exception("Invalid profile mass");
        var scheduler=new Stream(seed,"payback-v1:scheduler");
        var streams=new Stream[5]; var thresholds=new long[5];
        for(int h=0;h<5;h++) {
            streams[h]=new Stream(seed,"payback-v1:horse:"+h);
            thresholds[h]=(h==Pairs[r.Profile,0] || h==Pairs[r.Profile,1])?c.High:c.Low;
        }
        int[] units=new int[5],order=new int[5];
        int finishers=0;
        if(record) r.Trace=new int[250005];
        for(int round=1;round<=10000;round++) {
            scheduler.Shuffle(order);
            for(int slot=0;slot<5;slot++) {
                int h=order[slot],previous=units[h],step=streams[h].Raw()<thresholds[h]?2:1;
                units[h]+=step;
                if(previous<10000 && units[h]>=10000) {
                    r.Order[finishers]=h;
                    r.Times[finishers]=r.Events*.001+.001*(10000-previous)/step;
                    finishers++;
                }
                r.Events++;
                if(record) Array.Copy(units,0,r.Trace,r.Events*5,5);
                if(finishers==5) { r.Rounds=round; return r; }
            }
        }
        throw new Exception("Positive movement failed to terminate");
    }
    static string N(double value) { return value.ToString("R",CultureInfo.InvariantCulture); }
    public static void Run(string input,string configuration,string output,string samples) {
        CultureInfo.CurrentCulture=CultureInfo.InvariantCulture;
        var configs=new Dictionary<int,Configuration>();
        foreach(string line in File.ReadLines(configuration)) {
            var a=line.Split(',').Select(long.Parse).ToArray();
            configs[(int)a[0]]=new Configuration {High=a[1],Low=a[2],Mass=a.Skip(3).ToArray()};
        }
        if(File.Exists(output)||File.Exists(samples)) throw new Exception("Refusing to replace evidence");
        var watch=Stopwatch.StartNew(); int count=0;
        using(var writer=new StreamWriter(output))
        using(var traceWriter=new StreamWriter(samples)) {
            writer.WriteLine("id,seed,percent,profile,first,second,events,rounds,first_time,second_time,o0,o1,o2,o3,o4");
            traceWriter.WriteLine("id,index,p0,p1,p2,p3,p4");
            foreach(string line in File.ReadLines(input)) {
                var a=line.Split(','); int percent=int.Parse(a[2]); bool record=a[3]=="1";
                var r=Race(a[1],configs[percent],record);
                writer.WriteLine(string.Join(",",new[]{a[0],a[1],a[2],r.Profile.ToString(),r.Order[0].ToString(),r.Order[1].ToString(),r.Events.ToString(),r.Rounds.ToString(),N(r.Times[0]),N(r.Times[1])})+","+string.Join(",",r.Order));
                if(record) for(int index=0;index<=1000;index++) {
                    double time=r.Times[1]*index/1000.0;
                    int e=Math.Min((int)Math.Floor(time/.001),r.Events-1);
                    double alpha=Math.Clamp((time-e*.001)/.001,0,1);
                    var values=new string[5];
                    for(int h=0;h<5;h++) {
                        double start=r.Trace[e*5+h]*.1,end=r.Trace[(e+1)*5+h]*.1;
                        values[h]=N(start+(end-start)*alpha);
                    }
                    traceWriter.WriteLine(a[0]+","+index+","+string.Join(",",values));
                }
                count++;
                if(count%5000==0) { writer.Flush(); traceWriter.Flush(); Console.WriteLine(count+" races; elapsed "+watch.Elapsed); }
            }
        }
        Console.WriteLine("Completed "+count+" movement races in "+watch.Elapsed);
    }
}
