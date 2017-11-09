defmodule Cracker.Application do
  use Application

  def start(_type, _args) do
    Supervisor.start_link([
      %{id: Cracker.Dispatcher,
        start: {Cracker.Dispatcher, :start_link, []},
        restart: :transient}
    ], strategy: :one_for_one, name: Cracker.Supervisor)
  end
end
