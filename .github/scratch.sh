cd hardware
rm -rf /tmp/g && cp -r . /tmp/g && cd /tmp/g
sed -i 's/gearmotor := GearedMotor(roll: handle_open,/gearmotor := GearedMotor(roll: 0deg,/' radiatorbot.sv
grep -n "GearedMotor(roll" radiatorbot.sv
echo "== G unit frozen"; /usr/bin/time -f "%e s" solventc --no-progress --no-check --set shaped=0 radiatorbot.sv 2>&1 | grep -E "followed| s$|error|params|solve" | head || true
