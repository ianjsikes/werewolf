defmodule Werewolf.Player do
  alias __MODULE__

  defstruct name: "",
            is_owner: false,
            uuid: nil

  def new(name, is_owner \\ false) do
    %Player{name: name, is_owner: is_owner, uuid: Nanoid.generate()}
  end
end
