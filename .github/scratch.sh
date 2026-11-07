cd hardware
git show origin/main:hardware/radiatorbot.sv > old_bot.sv 2>/dev/null || git show 935a57e:hardware/radiatorbot.sv > old_bot.sv
echo "== old"; time solventc --no-progress --no-check old_bot.sv 2>&1 | grep -E "params|followed" || true
echo "== new"; time solventc --no-progress --no-check radiatorbot.sv 2>&1 | grep -E "params|followed" || true
