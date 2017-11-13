defmodule Cracker.DispatcherSupervisor do
  use Supervisor

  def start_link(num_workers) do
    Supervisor.start_link(__MODULE__, num_workers, name: __MODULE__)
  end

  def init(num_workers) do
    workers = Enum.map(1..num_workers, fn worker_num ->
      %{
        id: "Worker-#{worker_num}",
        start: {Cracker.Worker, :start_link, [worker_num]},
        restart: :permanent,
        shutdown: 5000,
        type: :worker
      }
    end)
    Supervisor.init(workers, strategy: :one_for_one)
  end

end
