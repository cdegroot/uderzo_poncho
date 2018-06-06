use Mix.Config

# We need to add some stuff for HAT screens for RPi3 through fwup
config :nerves, :firmware,
  fwup_conf: "config/fwup-rpi3.conf"
