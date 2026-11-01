#!/usr/bin/env python3
"""Synthetic, isolated statistics game/Hello acceptance. No production endpoints/secrets."""
import argparse,json,re,threading,time
from datetime import datetime,timezone
from http.server import BaseHTTPRequestHandler,ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs,urlparse
USER='00000000-0000-4000-8000-000000001005'
class State:
    calls=[];batches=[];failure=None;hello=False;revision=0;values={'kills':0,'rounds':0,'best_score':0};first=None;expired=None;gets=0;signup=0;scores=0
LOCK=threading.Lock()
def snapshot(operation=None,replayed=False):
    result=dict(userId=USER,definitionVersion=1,revision=State.revision,
        definitions=[dict(key=k,name=k,mode='max' if k=='best_score' else 'sum',reset='none') for k in State.values],
        values=[dict(key=k,value=v,hasValue=bool(State.revision),period=None) for k,v in State.values.items()],
        operationWindow=dict(serverTimeUnixMillis=int(datetime.now(timezone.utc).timestamp()*1000)-172800000,maxAgeSeconds=86400,maxFutureSkewSeconds=30),newlyUnlocked=[])
    if operation is not None:result.update(operationId=operation,replayed=replayed)
    return result
class Handler(BaseHTTPRequestHandler):
    def log_message(self,*_):pass
    def reply(self,status,value):
        raw=json.dumps(value).encode();self.send_response(status);self.send_header('Content-Type','application/json');self.send_header('Content-Length',str(len(raw)));self.end_headers()
        try:self.wfile.write(raw)
        except (BrokenPipeError,ConnectionResetError):pass
    def bad(self,message):State.failure=message;self.reply(422,dict(code='FIXTURE_CONTRACT',message=message))
    def do_GET(self):self.contract()
    def do_POST(self):self.contract()
    def contract(self):
        url=urlparse(self.path);route=url.path;body=json.loads(self.rfile.read(int(self.headers.get('Content-Length','0'))) or b'{}')
        State.calls.append(dict(route=route,method=self.command,operationId=body.get('operationId')))
        if route=='/actuator/health':return self.reply(200,dict(status='UP'))
        if route=='/api/v1/app/user-management/signup':
            State.signup+=1
            if State.signup!=1 or body.get('type')!='ANONYMOUS':return self.bad('Guest identity was recreated')
            return self.reply(200,dict(userId=USER,username='StatisticsFixture',accessToken='task1005-fixture-session',anonymousToken='task1005fixtureanonymous00000000',isAnonymous=True,isVerified=False))
        if route=='/api/v1/app/user-management/check-auth':return self.reply(401,dict(code='SESSION_EXPIRED',message='Deliberate protected guest recovery test'))
        if route=='/api/v1/app/user-management/signin':
            if body!={'type':'ANONYMOUS','anonymousToken':'task1005fixtureanonymous00000000'}:return self.bad('Validated original guest credential changed')
            return self.reply(401,dict(code='INVALID_ANONYMOUS_TOKEN',message='Deliberate protected guest recovery failure'))
        if self.headers.get('Authorization')!='Bearer task1005-fixture-session' or self.headers.get('X-API-Key')!='task1004-example-fixture':return self.bad('Wrong original player/project/session')
        if route=='/api/v1/app/statistics':
            if self.command=='GET':
                if parse_qs(url.query).get('userId')!=[USER]:return self.bad('Foreign statistics GET')
                State.gets+=1
                if not State.hello and State.gets==6:time.sleep(.3)
                return self.reply(200,snapshot())
            if self.command!='POST' or set(body)!={'userId','operationId','updates'} or body['userId']!=USER or not re.fullmatch(r'\d{13}:[0-9a-fA-F-]{36}',body['operationId']):return self.bad('Malformed original batch')
            if abs(int(body['operationId'].split(':')[0])-(int(datetime.now(timezone.utc).timestamp()*1000)-172800000))>30000:return self.bad('Operation ID assigned before server-clock synchronization')
            expected=[dict(key='kills',value=3 if State.hello else 2),dict(key='rounds',value=1),dict(key='best_score',value=1200 if State.hello else 10)]
            with LOCK:
                State.batches.append(body)
                if State.first is None:
                    if body['updates']!=expected:return self.bad('Completed run was not one exact three-counter batch')
                    State.first=body
                    State.values.update({v['key']:v['value'] for v in expected});State.revision=1
                if body['operationId']==State.first['operationId']:
                    if body!=State.first:return self.bad('Original batch payload changed')
                    if not State.hello and len(State.batches)<=2:return self.reply(503,dict(code='TEMPORARY',message='Deliberately lost original receipt after commit'))
                    return self.reply(200,snapshot(body['operationId'],not State.hello))
                if State.hello:return self.bad('Hello sent an extra batch')
                expired=[dict(key='kills',value=0),dict(key='rounds',value=1),dict(key='best_score',value=0)]
                if body['updates']!=expired:return self.bad('Expiry fixture payload changed')
                if State.expired is None:State.expired=body
                if body!=State.expired:return self.bad('Expired original was silently rebooked')
                return self.reply(410,dict(code='OPERATION_EXPIRED',message='Deliberate evicted-operation floor'))
        if route=='/api/v1/app/user-logs/create':
            if State.hello or body.get('userId')!=USER or body.get('type')!='INFO':return self.bad('Unexpected game log')
            return self.reply(200,dict(id='00000000-0000-4000-8000-000000009005',createdAt='2026-10-16T00:00:00Z'))
        if route in ('/api/v1/app/leaderboard/submit','/api/v1/app/leaderboards/default/submit'):
            State.scores+=1
            if body.get('userId')!=USER or body.get('score')!=(1000 if State.hello else 10 if State.scores==1 else 0) or State.scores>(1 if State.hello else 2):return self.bad('Unexpected actual run/Hello score')
            return self.reply(200,dict(success=True))
        if route in ('/api/v1/app/leaderboard/rank','/api/v1/app/leaderboards/default/rank'):return self.reply(200,dict(userId=USER,score=10,position=1,username='Fixture'))
        return self.bad('Unexpected route: '+route)
def main():
    p=argparse.ArgumentParser();p.add_argument('--port',type=int,default=18813);p.add_argument('--ready',type=Path,required=True);p.add_argument('--result',type=Path,required=True);p.add_argument('--hello',action='store_true');a=p.parse_args();State.hello=a.hello
    server=ThreadingHTTPServer(('127.0.0.1',a.port),Handler);a.ready.write_text('ready\n')
    try:server.serve_forever(poll_interval=.2)
    finally:
        a.result.write_text(json.dumps(dict(calls=State.calls,batches=State.batches,revision=State.revision,values=State.values,signup=State.signup,scores=State.scores,gets=State.gets,failure=State.failure),indent=2)+'\n');server.server_close()
if __name__=='__main__':
    import signal
    signal.signal(signal.SIGTERM,lambda *_:(_ for _ in ()).throw(KeyboardInterrupt()))
    try:main()
    except KeyboardInterrupt:pass
