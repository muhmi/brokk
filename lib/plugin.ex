defmodule Brokk.Plugin do

  defmacro __using__(_options \\ []) do
    quote do

      @behaviour Brokk.Plugin

      require Logger

      def init(brokk_config) do
        Logger.debug "Starting..."
        :ok
      end

      def on_message(from, {:text, message}) do
        Logger.debug "Ignoring message #{message} from #{inspect from}"
        :noreply
      end

      defoverridable [init: 1, on_message: 2]

      Module.register_attribute(__MODULE__, :plugins, accumulate: true)

    end
  end

  use Behaviour

  @doc ~S"""
  Override this if the plugin needs some custom initialization
  """
  @callback init(config :: Map.t) :: :ok

  @doc ~S"""
  This function defines the behaviour of the plugin. You can reply to messages
  `{:reply, {:text, "reply"}}`, ignore them with `:noreply` or halt the processing by returning
  `:halt`
  """
  @callback on_message(from :: any, msg :: any) :: {:reply, any} | :noreply | :halt

end
