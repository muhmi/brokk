defmodule Brokk.Adapter.FlowdockSupervisor do
  use Supervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      worker(Brokk.Adapter.Flowdock, [[name: Brokk.Adapter.Flowdock]])
    ]
    supervise(children, strategy: :one_for_one)
  end
end

defmodule Brokk.Adapter.Flowdock do

  @behaviour Brokk.Adapter

  use GenServer

  def child_spec do
    import Supervisor.Spec, warn: false
    supervisor(Brokk.Adapter.FlowdockSupervisor, [[name: Brokk.Adapter.FlowdockSupervisor]])
  end

  def start_link(opts \\ []) do
    GenServer.start_link __MODULE__, opts, opts
  end

  def init(_opts \\ []) do
    {:ok, %{}}
  end

  def env do
    Application.get_env(:brokk, :flowdock)
  end

end