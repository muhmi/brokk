defmodule Brokk.Plugins.Consume do

  use Brokk.Plugin

  def on_message(_from, {:text, _message}) do
    :halt
  end

end