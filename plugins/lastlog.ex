defmodule Brokk.Plugins.LastLog do

  use Brokk.Plugin

  alias Brokk.Brain

  # how many items to keep
  @log_length 50

  def on_message(_from, {:text, "/lastlog"}) do
    log =
      get_log
      |> Enum.map(fn {sender_name, timestamp, message} ->
          "#{timestamp} @#{sender_name}: #{message}\n"
        end)
    {:reply, log}
  end
  def on_message(from, {:text, message}) do
    entry = {from, :os.system_time(:seconds), message}
    Brain.update :lastlog, [entry|get_log]
    :noreply
  end

  def get_log do
    case Brain.lookup(:lastlog) do
      {:ok, log} -> log
      _any -> []
    end
  end

end