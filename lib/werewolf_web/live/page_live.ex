defmodule WerewolfWeb.PageLive do
  use WerewolfWeb, :live_view
  alias Werewolf.{GameCoordinator, GameServer}

  def mount(_params, _session, socket) do
    {:ok,
     assign(
       socket,
       player_uuid: nil,
       player: nil,
       game_uuid: nil,
       game_state: nil,
       new_game_player_name: "",
       join_game_player_name: "",
       join_game_room_code: ""
     )}
  end

  def render(assigns) do
    case assigns.game_state do
      nil ->
        Phoenix.View.render(WerewolfWeb.GameView, "join.html", assigns)

      _ ->
        Phoenix.View.render(WerewolfWeb.GameView, "lobby.html", assigns)
    end
  end

  #####################
  # LOBBY FORM HANDLERS
  #####################

  def handle_event("new_game_change", %{"player_name" => player_name}, socket) do
    {:noreply, assign(socket, new_game_player_name: player_name)}
  end

  def handle_event("new_game_submit", %{"player_name" => player_name}, socket) do
    case player_name do
      "" ->
        {:noreply,
         socket
         |> put_flash(:error, "Name must not be empty")}

      _ ->
        {player, game_state} = GameCoordinator.new_game(player_name)
        :ok = Phoenix.PubSub.subscribe(Werewolf.PubSub, "game:" <> game_state.uuid)

        {:noreply,
         assign(
           socket,
           player_uuid: player.uuid,
           player: player,
           game_uuid: game_state.uuid,
           game_state: game_state,
           new_game_player_name: ""
         )}
    end
  end

  def handle_event(
        "join_game_change",
        %{"player_name" => player_name, "room_code" => room_code},
        socket
      ) do
    {:noreply, assign(socket, join_game_player_name: player_name, join_game_room_code: room_code)}
  end

  def handle_event(
        "join_game_submit",
        %{"player_name" => player_name, "room_code" => room_code},
        socket
      ) do
    if player_name == "" or room_code == "" or String.length(room_code) != 5 do
      {:noreply, put_flash(socket, :error, "Invalid data")}
    else
      case GameCoordinator.join_game(room_code, player_name) do
        {player, game_state} ->
          :ok = Phoenix.PubSub.subscribe(Werewolf.PubSub, "game:" <> game_state.uuid)

          {:noreply,
           assign(socket,
             player_uuid: player.uuid,
             player: player,
             game_uuid: game_state.uuid,
             game_state: game_state,
             join_game_player_name: "",
             join_game_room_code: ""
           )}

        :not_found ->
          {:noreply,
           socket
           |> put_flash(:error, "No game found with room code " <> room_code)
           |> assign(join_game_player_name: "", join_game_room_code: "")}
      end
    end
  end

  #####################
  # GAME EVENT HANDLERS
  #####################

  def handle_event("leave_game", _arg, socket) do
    Phoenix.PubSub.unsubscribe(Werewolf.PubSub, "game:" <> socket.assigns.game_uuid)
    GameCoordinator.leave_game(socket.assigns.game_uuid, socket.assigns.player_uuid)

    {:noreply,
     assign(
       socket,
       player_uuid: nil,
       player: nil,
       game_uuid: nil,
       game_state: nil
     )}
  end

  def handle_info(:update, socket) do
    state = GameServer.state(socket.assigns.game_uuid)

    {:noreply,
     assign(
       socket,
       game_state: state,
       player:
         case Map.fetch(state.players, socket.assigns.player_uuid) do
           {:ok, player} -> player
           _ -> socket.assigns.player
         end
     )}
  end
end
