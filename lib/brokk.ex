defmodule Brokk do
  use Application

  require Logger

  import Brokk.Guards

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Logger.info "Starting with brain #{Brokk.Brain.impl}"

    children = [
      Brokk.Brain.child_spec,
      Brokk.Worker.child_spec
    ]

    adapters =
      Application.get_env(:brokk, :adapters, [])
      |> Enum.map(fn adapter -> adapter.child_spec end)

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Brokk.Supervisor]
    Supervisor.start_link(children ++ adapters, opts)
  end

  @doc ~S"""
  Tell the bot it has received a message from someone
  """
  def receive(sender, message) when is_sender(sender) and is_binary(message) do
    Brokk.Worker.receive_message(sender, message)
  end

  @doc ~S"""
  Tell the bot to reply to some reiceiver
  """
  def reply(reiceiver, message) when is_sender(reiceiver) and is_binary(message) do
    Brokk.Worker.send_reply(reiceiver, message)
  end

end
