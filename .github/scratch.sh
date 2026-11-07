set -x
cd hardware
time solventc radiatorbot.sv --where unit_at --where p_c --where a_c || true
