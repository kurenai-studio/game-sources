#!/usr/bin/env python3
"""Loopback-only native example acceptance fixture. Synthetic credentials, no external access."""
import argparse, json, threading
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

USER = '00000000-0000-4000-8000-000000001004'
class State:
    revision, gold, energy, offers, purchases, adjustments = 1, 100, 0, 0, 0, 0
    purchase_id, ready = None, False
    scores = 0
    calls = []
def version(): return 1 if State.offers<2 else 2 if State.offers<4 else 3
def now(): return datetime.now(timezone.utc).isoformat(timespec='milliseconds').replace('+00:00','Z')
def snapshot(operation=None):
    return dict(userId=USER,day='2026-10-16',revision=State.revision,definitionVersion=version(),
        values=[dict(key=k,balance=v,earnedToday=0,dailyCap=None) for k,v in [('gold',State.gold),('energy',State.energy)]],
        operationWindow=dict(serverTime=now(),oldestAcceptedAt='2026-09-16T00:00:00Z'),operation=operation)
class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_): pass
    def reply(self, status, value):
        raw=json.dumps(value).encode();self.send_response(status);self.send_header('Content-Type','application/json');self.send_header('Content-Length',str(len(raw)));self.end_headers();self.wfile.write(raw)
    def do_GET(self): self.handle_request()
    def do_POST(self): self.handle_request()
    def handle_request(self):
        route=self.path.split('?')[0];body=json.loads(self.rfile.read(int(self.headers.get('Content-Length','0'))) or b'{}')
        State.calls.append(dict(route=route,method=self.command,operationId=body.get('operationId')))
        if route=='/actuator/health': return self.reply(200,dict(status='UP'))
        if route=='/api/v1/app/user-management/signup':
            return self.reply(200,dict(userId=USER,username='Task1004Fixture',accessToken='task1004-fixture-session',anonymousToken='task1004fixtureanonymous00000000',isAnonymous=True,isVerified=False))
        if route=='/api/v1/app/leaderboard/submit':
            if body.get('userId')!=USER or body.get('score')!=1000 or self.headers.get('Authorization')!='Bearer task1004-fixture-session':
                return self.reply(400,dict(code='INVALID_REQUEST',message='Exact Hello score/session required'))
            State.scores+=1
            return self.reply(200,dict(success=True))
        if route.startswith('/api/v1/app/player-values'):
            if self.headers.get('X-API-Key')!='task1004-example-fixture' or self.headers.get('Authorization')!='Bearer task1004-fixture-session':
                return self.reply(403,dict(code='SESSION_FORBIDDEN',message='Fixture credentials required'))
            if route.endswith('/offers'):
                State.offers+=1;catalog=version()
                return self.reply(200,dict(definitionVersion=catalog,serverTime=now(),definitions=[],offers=[dict(key='energy-pack',name='Energy',active=True,purchasesPerDay=None,costs=[dict(key='gold',amount=5 if catalog==1 else 7 if catalog==2 else 9)],rewards=[dict(key='energy',amount=10)])]))
            if route.endswith('/purchase'):
                State.purchases+=1;op=body.get('operationId')
                if body.get('userId')!=USER or body.get('offerKey')!='energy-pack' or not op:
                    return self.reply(400,dict(code='INVALID_REQUEST',message='Original purchase required'))
                if State.purchase_id is None:
                    State.purchase_id=op;State.gold-=7;State.energy+=10;State.revision+=1
                if State.purchase_id!=op:
                    return self.reply(409,dict(code='STATE_CONFLICT',message='Original ID was replaced'))
                if State.purchases<=2: return self.reply(503,dict(code='TEMPORARY',message='Deliberately lost receipt after commit'))
                return self.reply(200,snapshot(dict(operationId=op,replayed=True,applied=[dict(key='gold',amount=-7),dict(key='energy',amount=10)])))
            if route.endswith('/adjust'):
                if body.get('userId')!=USER or body.get('key')!='energy' or body.get('amount')!=-1 or body.get('operationId')==State.purchase_id:
                    return self.reply(400,dict(code='INVALID_REQUEST',message='Exact adjustment required'))
                State.adjustments+=1;State.energy-=1;State.revision+=1
                return self.reply(200,snapshot(dict(operationId=body['operationId'],replayed=False,applied=[dict(key='energy',amount=-1)])))
            return self.reply(200,snapshot())
        self.reply(404,dict(code='NOT_FOUND',message='No fixture route'))
def main():
    p=argparse.ArgumentParser();p.add_argument('--port',type=int,default=18814);p.add_argument('--ready',type=Path,required=True);p.add_argument('--result',type=Path,required=True);a=p.parse_args()
    server=ThreadingHTTPServer(('127.0.0.1',a.port),Handler)
    a.ready.write_text('ready\n')
    try: server.serve_forever(poll_interval=.2)
    finally:
        a.result.write_text(json.dumps(dict(calls=State.calls,scores=State.scores,purchases=State.purchases,adjustments=State.adjustments,gold=State.gold,energy=State.energy,purchaseId=State.purchase_id),indent=2)+'\n')
if __name__=='__main__':
    import signal
    signal.signal(signal.SIGTERM,lambda *_: (_ for _ in ()).throw(KeyboardInterrupt()))
    try: main()
    except KeyboardInterrupt: pass
