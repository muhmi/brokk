# https://github.com/github/hubot-scripts/blob/master/src/scripts/fortune.coffee
defmodule Brokk.Plugins.Fortune do

  use Brokk.Plugin

  def on_message(from, {:text, "/fortune"}) do
    spawn fn -> fetch_fortune(from) end
    :noreply
  end
  def on_message(_, _), do: :noreply

  defp fetch_fortune(caller) do
    case HTTPoison.get("http://www.fortunefortoday.com/getfortuneonly.php") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Brokk.reply caller, String.strip(body)
      _any ->
        :cant_send_fortune
    end
  end

end