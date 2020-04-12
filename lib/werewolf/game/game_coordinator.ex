# GameCoordinator... coordinates games. Contains functions to create/join/leave games.

# TODO: Use a DynamicSupervisor to actually start the GameServers rather than linking
# them directly to this process.
defmodule Werewolf.GameCoordinator do
  use GenServer
  alias Werewolf.{GameServer}

  @name {:global, __MODULE__}

  defmodule GameCoordinator do
    defstruct games: %{}
  end

  # This starts an instance of this server. It gets invoked by the Supervisor.
  # The second argument is a struct containing the state for the server.
  def start_link(_init_args) do
    GenServer.start_link(__MODULE__, %GameCoordinator{}, name: @name)
  end

  # This gets called on the server instance. It is passed the second argument of `start_link`.
  def init(server) do
    {:ok, server}
  end

  ############
  # PUBLIC API
  ############

  def state(), do: GenServer.call(@name, :state)

  def new_game(player_name) do
    GenServer.call(@name, {:new_game, player_name})
  end

  def join_game(game_uuid, player_name),
    do: GenServer.call(@name, {:join_game, game_uuid, player_name})

  def leave_game(game_uuid, player_uuid) do
    GenServer.cast(@name, {:leave_game, game_uuid, player_uuid})
  end

  def end_game(game_uuid), do: GenServer.cast(@name, {:end_game, game_uuid})

  ###########
  # CALLBACKS
  ###########

  def handle_call(:state, _from, state), do: {:reply, state, state}

  def handle_call({:new_game, player_name}, _from, state) do
    new_game_uuid = Nanoid.generate(5)
    {:ok, new_game_pid} = GameServer.start_link(new_game_uuid)
    player = GameServer.join(new_game_uuid, player_name)
    game_state = GameServer.state(new_game_uuid)

    new_state = %{state | games: Map.put(state.games, new_game_uuid, %{pid: new_game_pid})}
    {:reply, {player, game_state}, new_state}
  end

  def handle_call({:join_game, game_uuid, player_name}, _from, state) do
    case Map.fetch(state.games, game_uuid) do
      {:ok, _game_pid} ->
        player = GameServer.join(game_uuid, player_name)
        game_state = GameServer.state(game_uuid)

        {:reply, {player, game_state}, state}

      _ ->
        {:reply, :not_found, state}
    end
  end

  def handle_cast({:leave_game, game_uuid, player_uuid}, state) do
    GameServer.leave(game_uuid, player_uuid)
    {:noreply, state}
  end

  def handle_cast({:end_game, game_uuid}, state) do
    {:noreply, %{state | games: Map.delete(state.games, game_uuid)}}
  end
end
