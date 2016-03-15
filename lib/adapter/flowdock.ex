defmodule Brokk.Adapter.FlowdockSupervisor do
  use Supervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children =
      Enum.map(flows||[], fn flow ->
        worker(Brokk.Adapter.Flowdock, [[name: Brokk.Adapter.Flowdock, flow: flow, apikey: env[:apikey]]])
      end)
    supervise(children, strategy: :one_for_one)
  end

  def flows do
    String.split(env[:flows] || "", ",") |> Enum.map(fn s -> String.strip(s) end)
  end

  def env do
    Application.get_env(:brokk, :flowdock)
  end
end

defmodule Brokk.Adapter.Flowdock do

  @behaviour Brokk.Adapter

  @cooldown_ms 5_000

  @recv_timeout 60_000

  use GenServer

  require Logger

  def child_spec do
    import Supervisor.Spec, warn: false
    supervisor(Brokk.Adapter.FlowdockSupervisor, [[name: Brokk.Adapter.FlowdockSupervisor]])
  end

  def start_link(opts \\ []) do
    GenServer.start_link __MODULE__, opts, opts
  end

  def init(opts \\ []) do
    apikey = opts[:apikey]
    flow = opts[:flow]
    %HTTPoison.AsyncResponse{id: id} = HTTPoison.get! "https://#{apikey}@stream.flowdock.com/flows?filter=#{flow}", %{}, [stream_to: self, recv_timeout: @recv_timeout]
    {:ok, %{async_id: id, flow: flow, apikey: apikey}}
  end

  def handle_info(:stop, state) do
    {:stop, :normal, state}
  end

  def handle_info({:text, message}, state) do
    case HTTPoison.post("https://#{state.apikey}@api.flowdock.com/flows/#{state.flow}/messages", "event=message&content=#{message}", [{"Content-Type", "multipart/form-data"}]) do
      {:ok, _res} -> Logger.debug("send message #{message}")
      {:error, reason} -> Logger.debug("failed to send message, reason #{inspect reason}")
    end
    {:noreply, state}
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
    case msg  do
      %{"event" => "message", "content" => content} ->
        filter(content)
      %{"event" => "message-edit", "content" => %{"updated_content" => content}} ->
        filter(content)
      _any ->
        Logger.debug "unknown message received #{json}"
    end
    {:noreply, state}
  end

  def handle_info(%HTTPoison.Error{reason: {:closed, :timeout}}, state) do
    Logger.debug "connection closed, timeout"
    {:stop, :normal, state}
  end

  def handle_info(%HTTPoison.Error{reason: reason}, state) do
    Logger.debug "HTTP error #{inspect reason}, shutting down in #{@cooldown_ms}ms"
    Process.send_after self, :stop, @cooldown_ms
    {:noreply, state}
  end

  @doc "Convert `.command`s to `/command`"
  def filter(content) when is_binary(content) do
    case String.strip(content) do
      "." <> command -> Brokk.receive(self, "/#{command}")
      message -> Brokk.receive(self, message)
    end
  end
end