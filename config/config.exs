# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :werewolf,
  ecto_repos: [Werewolf.Repo]

# Configures the endpoint
config :werewolf, WerewolfWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "asOpF7KNhIp04gN9gfUHvxvDgOyBtDrchUqldB81xb2s3jg7fMK2p//i2x0d2EWv",
  render_errors: [view: WerewolfWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Werewolf.PubSub,
  live_view: [signing_salt: "tlQxck2j"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
