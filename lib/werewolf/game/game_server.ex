defmodule Werewolf.GameServer do
  use GenServer
  alias Werewolf.{GameCoordinator}

  defmodule GameState do
    defstruct uuid: nil,
              players: %{},
              player_count: 0
  end

  def start_link(game_uuid) do
    state = %GameState{uuid: game_uuid}

    GenServer.start_link(__MODULE__, state, name: {:global, game_uuid})
  end

  def init(state) do
    # Here is where I can start a timer
    {:ok, state}
  end

  def terminate(_reason, state) do
    GameCoordinator.end_game(state.uuid)
  end

  def state(game_uuid) do
    GenServer.call({:global, game_uuid}, :state)
  end

  def join(game_uuid, player_name) do
    response = GenServer.call({:global, game_uuid}, {:join, player_name})
    Phoenix.PubSub.broadcast(Werewolf.PubSub, "game:" <> game_uuid, :update)
    response
  end

  def leave(game_uuid, player_uuid) do
    GenServer.cast({:global, game_uuid}, {:leave, player_uuid})
    Phoenix.PubSub.broadcast(Werewolf.PubSub, "game:" <> game_uuid, :update)
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:join, player_name}, _from, state) do
    player = Werewolf.Player.new(player_name)

    new_state = %{
      state
      | players: Map.put(state.players, player.uuid, player),
        player_count: state.player_count + 1
    }

    {:reply, player, new_state}
  end

  def handle_cast({:leave, player_uuid}, state) do
    case Map.fetch(state.players, player_uuid) do
      {:ok, _player} ->
        new_players = Map.delete(state.players, player_uuid)
        new_state = %{state | players: new_players, player_count: state.player_count - 1}

        if new_state.player_count == 0 do
          {:stop, :normal, new_state}
        else
          {:noreply, new_state}
        end

      _ ->
        {:noreply, state}
    end
  end
end
