"""Terminate our own failed diagnostic process promptly; retain every error line."""
import subprocess,time

def checked_process(args,*,cwd,env,log,timeout):
 start=time.monotonic()
 with log.open('w',encoding='utf-8')as output:
  child=subprocess.Popen(args,cwd=cwd,env=env,stdout=output,stderr=subprocess.STDOUT)
  errors=False
  while child.poll() is None:
   time.sleep(.2)
   text=log.read_text(encoding='utf-8',errors='replace')
   errors=any(marker in text for marker in ['ERROR:','SCRIPT ERROR:','Parse Error'])
   if errors or time.monotonic()-start>timeout:
    child.terminate()
    try:child.wait(timeout=10)
    except subprocess.TimeoutExpired:child.kill();child.wait()
    break
 text=log.read_text(encoding='utf-8',errors='replace')
 return dict(seconds=round(time.monotonic()-start,3),exit_code=child.returncode,errors=errors or any(marker in text for marker in ['ERROR:','SCRIPT ERROR:','Parse Error']),timeout=time.monotonic()-start>timeout)
