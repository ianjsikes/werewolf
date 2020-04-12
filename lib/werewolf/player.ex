defmodule Werewolf.Player do
  alias __MODULE__

  defstruct name: "",
            uuid: nil

  def new(name) do
    %Player{name: name, uuid: Nanoid.generate()}
  end
end
