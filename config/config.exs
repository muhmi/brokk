# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :logger, :console,
  format: "$node $date $time $metadata[$level] $message\n",
  metadata: [:module, :line],
  truncate: 512_000,
  utc_log: true

config :brokk,
  plugins: [
    Brokk.Plugins.Echo,
    Brokk.Plugins.Fortune,
    Brokk.Plugins.GeocodeMe,
    Brokk.Plugins.Base64,

    # Stupid plugins processed last
    Brokk.Plugins.Adult,
    Brokk.Plugins.Alot,
  ],
  adapters: [
    Brokk.Adapter.Flowdock
  ],

  flowdock: [
    # api key for accessing Streams and Messages APIs
    apikey: System.get_env("FLOWDOCK_API_KEY"),
    # Expected to be a comma separated list of flows like "org/flow,org/flow"
    flows: System.get_env("FLOWDOCK_FLOWS")
  ]

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
# import_config "#{Mix.env}.exs"
