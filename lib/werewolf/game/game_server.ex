defmodule Werewolf.GameServer do
  use GenServer
  alias Werewolf.{GameCoordinator}

  defmodule GameState do
    defstruct uuid: nil,
              owner_id: nil,
              players: %{},
              player_ids_in_join_order: [],
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

  def join(game_uuid, player_name, is_owner \\ false) do
    response = GenServer.call({:global, game_uuid}, {:join, player_name, is_owner})
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

  def handle_call({:join, player_name, is_owner}, _from, state) do
    player = Werewolf.Player.new(player_name, is_owner)

    new_state = %{
      state
      | players: Map.put(state.players, player.uuid, player),
        player_ids_in_join_order: state.player_ids_in_join_order ++ [player.uuid],
        player_count: state.player_count + 1,
        owner_id: if(is_owner, do: player.uuid, else: state.owner_id)
    }

    {:reply, player, new_state}
  end

  def handle_cast({:leave, player_uuid}, state) do
    case Map.fetch(state.players, player_uuid) do
      {:ok, _player} ->
        new_ids_in_join_order = state.player_ids_in_join_order -- [player_uuid]
        new_owner_id = List.first(new_ids_in_join_order)

        {_, new_players} =
          state.players
          |> Map.delete(player_uuid)
          |> Map.get_and_update(new_owner_id, fn player ->
            {player, %{player | is_owner: true}}
          end)

        new_state = %{
          state
          | players: new_players,
            player_count: state.player_count - 1,
            player_ids_in_join_order: new_ids_in_join_order,
            owner_id: new_owner_id
        }

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
