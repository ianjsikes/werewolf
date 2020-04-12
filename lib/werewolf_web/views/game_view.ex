defmodule WerewolfWeb.GameView do
  use WerewolfWeb, :view

  def player_title(player, assigns) do
    title = player.name
    title = if player.is_owner, do: "⭐️ " <> title, else: title
    title = if player.uuid == assigns.player_uuid, do: title <> " (YOU)", else: title
    title
  end

  def disable_if(true), do: "disabled"
  def disable_if(false), do: nil
end
