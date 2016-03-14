defmodule Brokk.Worker.Supervisor do
  use Supervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
    	worker(Brokk.Worker, [[name: Brokk.Worker]])
    ]
    supervise(children, strategy: :one_for_one)
  end
end

defmodule Brokk.Worker do

  use GenServer

  import Brokk.Guards

  require Logger

  def start_link(opts \\ %{}) do
    GenServer.start_link(__MODULE__, opts, opts)
  end

  def init(_opts) do
    state = %{plugins: Application.get_env(:brokk, :plugins, [])}
    for plug <- state.plugins, do: plug.init(state)
    {:ok, state}
  end

  @doc "To be called for.ex. when the bot receives a message from a chat integration"
  def receive_message(sender, message) when is_sender(sender) and is_binary(message) do
    GenServer.cast __MODULE__, {:msg, sender, {:text, message}}
  end

  def handle_cast({:msg, sender, {:text, text} = _} = msg, state) when is_sender(sender) do
    Logger.debug "Received message #{text} from #{inspect sender}"
    call_plugins(msg, state.plugins)
    {:noreply, state}
  end

  def child_spec do
    import Supervisor.Spec, warn: false
    supervisor(Brokk.Worker.Supervisor, [[name: Brokk.Worker.Supervisor]])
  end

  def call_plugins({:msg, sender, message} = msg, [plug | rest]) when is_sender(sender) do
    res =
      case plug.on_message(sender, message) do
        {:reply, reply_msg} ->
          send_reply(sender, reply_msg)
          :halt
        :halt -> :halt
        :noreply -> :continue
      end
    if res == :continue do
      call_plugins(msg, rest)
    else
      {:halt, plug}
    end
  end
  def call_plugins(_, []), do: :ignored

  def send_reply(receiver, reply_msg) when is_pid(receiver) do
    send receiver, reply_msg
  end
  def send_reply(receiver, _) do
    Logger.debug "Dont know how to reply to #{inspect receiver}, ignoring."
  end

end