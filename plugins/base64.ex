# https://github.com/github/hubot-scripts/blob/master/src/scripts/adult.coffee
defmodule Brokk.Plugins.Base64 do

  use Brokk.Plugin
  
  def on_message(_from, {:text, "/base64 encode " <> message}) do
    {:reply, Base.encode64(message)}
  end
  def on_message(_from, {:text, "/base64 decode " <> message}) do
    {:reply, Base.decode64!(message)}
  end
  def on_message(_from, _any), do: :noreply

end