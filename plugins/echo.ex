defmodule Brokk.Plugins.Echo do

  use Brokk.Plugin

  def on_message(_from, {:text, "/echo " <> message}) do
    {:reply, message}
  end
  def on_message(_from, _any), do: :noreply

end