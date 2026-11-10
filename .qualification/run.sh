set -euo pipefail
mkdir qualification-evidence
probe=$(mktemp -d "$RUNNER_TEMP/ubuntu-probe.XXXXXX")
cp -a .qualification/files .qualification/pichi.yaml "$probe/"
pichi update "$probe" --pull never
 git -C "$probe" init -q
 git -C "$probe" add .
 git -C "$probe" -c user.name=Qualification -c user.email=qualification@localhost commit -qm 'test: qualify Ubuntu instance behavior'
pichi build "$probe" --ref HEAD --memory 8192 -t ubuntu:port-check
pichi inspect ubuntu:port-check > qualification-evidence/image.json
for run in first second fresh; do
  disk="$RUNNER_TEMP/ubuntu-state.raw"
  if [ "$run" = fresh ]; then disk="$RUNNER_TEMP/ubuntu-fresh.raw"; fi
  timeout --foreground 120 pichi run ubuntu:port-check --storage-file "$disk" > "qualification-evidence/$run.log" 2>&1
  grep -q 'old root unmounted' "qualification-evidence/$run.log"
  grep -q '^PORT_PASS' "qualification-evidence/$run.log"
  grep -q '^PORT_HOSTNAME=ubuntu-port-check' "qualification-evidence/$run.log"
done
python3 - <<'CHECK'
import pathlib,re,json
out=pathlib.Path('qualification-evidence')
rows={}
for name in ['first','second','fresh']:
 text=(out/(name+'.log')).read_text()
 mid=re.search(r'PORT_MACHINE_ID=([0-9a-f]{32})',text).group(1)
 dbus=re.search(r'PORT_DBUS_ID=([0-9a-f]{32})',text).group(1)
 count=int(re.search(r'PORT_STATE_COUNT=(\d+)',text).group(1))
 assert mid==dbus
 rows[name]={'id':mid,'count':count}
assert rows['first']['id']==rows['second']['id']!=rows['fresh']['id']
assert [rows[x]['count'] for x in ['first','second','fresh']]==[1,2,1]
(out/'results.json').write_text(json.dumps(rows,indent=2))
print(json.dumps(rows))
CHECK
