defmodule Brokk.Plugins.Explode do

  use Brokk.Plugin

  def on_message(_from, {:text, _message}) do
    raise "Explosion!"
  end

end