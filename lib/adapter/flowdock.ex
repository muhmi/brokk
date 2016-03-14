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

  require Logger

  def child_spec do
    import Supervisor.Spec, warn: false
    supervisor(Brokk.Adapter.FlowdockSupervisor, [[name: Brokk.Adapter.FlowdockSupervisor]])
  end

  def start_link(opts \\ []) do
    GenServer.start_link __MODULE__, opts, opts
  end

  def init(_opts \\ []) do
    %HTTPoison.AsyncResponse{id: id} = connect
    {:ok, %{async_id: id}}
  end

  def handle_info(%HTTPoison.AsyncStatus{code: 200, id: _id}, state) do
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncHeaders{}, state) do
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncChunk{chunk: "\n", id: _id}, state) do
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncChunk{chunk: json, id: _id}, state) when is_binary(json) do
    msg = Poison.decode! json
    if msg["event"] == "message" do
      Brokk.receive(self, msg["content"])
    end
    {:noreply, state}
  end

  def handle_info(%HTTPoison.Error{reason: reason}, state) do
    {:stop, :normal, state}
  end

  def connect do
    HTTPoison.get! "https://#{env[:apikey]}@stream.flowdock.com/flows?filter=#{env[:flows]}", %{}, stream_to: self
  end

  def env do
    Application.get_env(:brokk, :flowdock)
  end

end