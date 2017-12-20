gpd_power_battery_path="/sys/class/power_supply/max170xx_battery/"
gpd_power_usbc_path="/sys/class/power_supply/fusb302-typec-source/"
gpd_power_divisor=1000000
gpd_power_divisor_squared=$(( $gpd_power_divisor * $gpd_power_divisor ))

gpd_power_priority=100001
gpd_power_update_every=

gpd_power_battery_voltage=0
gpd_power_battery_current=0
gpd_power_battery_power=0
gpd_power_usbc_voltage=0
gpd_power_usbc_current=0
gpd_power_usbc_power=0

_gpd_power_get_value() {
  local value=$(cat "$1$2")
  echo $value
}

gpd_power_get() {
  gpd_power_battery_voltage=$(_gpd_power_get_value $gpd_power_battery_path "voltage_now")
  gpd_power_battery_current=$(_gpd_power_get_value $gpd_power_battery_path "current_now")
  gpd_power_battery_current=$(( -1 * $gpd_power_battery_current )) # Positive if discharging, negative if charging, for better view when charging
  gpd_power_battery_power=$(( $gpd_power_battery_voltage * $gpd_power_battery_current ))
  gpd_power_usbc_voltage=$(_gpd_power_get_value $gpd_power_usbc_path "voltage_now")
  gpd_power_usbc_current=$(_gpd_power_get_value $gpd_power_usbc_path "current_max")
  gpd_power_usbc_power=$(( $gpd_power_usbc_voltage * $gpd_power_usbc_current ))
}

gpd_power_check() {
  # Make sure we are on a supported GPD Pocket
  if [[ ! -d $gpd_power_battery_path ]] || [[ ! -d $gpd_power_usbc_path ]]; then
    return 1
  fi
  return 0
}

gpd_power_create() {
  cat <<EOF
CHART gpd_power.voltage '' "Voltage" "Volt (V)" gpd_power gpd_power line $(( $gpd_power_priority + 3 ))
DIMENSION battery '' absolute 1 $gpd_power_divisor
DIMENSION usbc '' absolute 1 $gpd_power_divisor
CHART gpd_power.current '' "Current" "Ampere (A)" gpd_power gpd_power line $(( $gpd_power_priority + 2 ))
DIMENSION battery '' absolute 1 $gpd_power_divisor
DIMENSION usbc 'usbc (max)' absolute 1 $gpd_power_divisor
CHART gpd_power.power '' "Power" "Watt (W)" gpd_power gpd_power line $(( $gpd_power_priority + 1 ))
DIMENSION battery '' absolute 1 $gpd_power_divisor_squared
DIMENSION usbc 'usbc (max)' absolute 1 $gpd_power_divisor_squared
EOF
  return 0
}

gpd_power_update() {
  gpd_power_get || return 1
  cat <<VALUESOF
BEGIN gpd_power.voltage $1
SET battery = $gpd_power_battery_voltage
SET usbc = $gpd_power_usbc_voltage
END
BEGIN gpd_power.current $1
SET battery = $gpd_power_battery_current
SET usbc = $gpd_power_usbc_current
END
BEGIN gpd_power.power $1
SET battery = $gpd_power_battery_power
SET usbc = $gpd_power_usbc_power
END
VALUESOF
  return 0
}
