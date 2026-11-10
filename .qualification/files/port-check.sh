set -eu
printf 'PORT_MACHINE_ID='
cat /etc/machine-id
printf 'PORT_DBUS_ID='
cat /var/lib/dbus/machine-id
cmp /etc/machine-id /var/lib/dbus/machine-id
for path in / /var/lib/dpkg; do
  options=$(findmnt -n -o OPTIONS --mountpoint "$path")
  case ",$options," in *,ro,*) ;; *) exit 1 ;; esac
done
options=$(findmnt -n -o OPTIONS --mountpoint /var)
case ",$options," in *,rw,*) ;; *) exit 1 ;; esac
count=0
test ! -e /var/lib/port-check-count || read -r count < /var/lib/port-check-count
count=$((count+1))
printf '%s\n' "$count" > /var/lib/port-check-count
printf 'PORT_STATE_COUNT=%s\n' "$count"
test -s /var/lib/dpkg/status
dpkg-query -W systemd e2fsprogs
printf 'PORT_HOSTNAME='
cat /proc/sys/kernel/hostname
printf 'PORT_FAILED_UNITS_BEGIN\n'
failed=$(systemctl --failed --no-legend --no-pager)
printf '%s\n' "$failed"
test -z "$failed"
printf 'PORT_FAILED_UNITS_END\n'
printf 'PORT_PASS\n'
