defmodule Cracker.Application do
  use Application

  def start(_type, _args) do
    Supervisor.start_link([
      %{id: Cracker.Generator,
        start: {Cracker.Generator, :start_link, []},
        restart: :transient}
    ], strategy: :one_for_one, name: Cracker.Supervisor)
  end
end
