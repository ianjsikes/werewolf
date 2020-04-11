defmodule Werewolf.Repo do
  use Ecto.Repo,
    otp_app: :werewolf,
    adapter: Ecto.Adapters.Postgres
end
