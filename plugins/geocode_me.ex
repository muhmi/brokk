# https://github.com/github/hubot-scripts/blob/master/src/scripts/geocodeme.coffee
defmodule Brokk.Plugins.GeocodeMe do

  use Brokk.Plugin

  require Logger

  def on_message(from, {:text, "/where is " <> location}) do
    spawn fn -> where_is(from, String.strip(location)) end
    :noreply
  end
  def on_message(_, _), do: :noreply

  def where_is(caller, address) when is_binary(address) do
    case fetch_address_cached(address) do
      {:ok, results} ->
        Brokk.reply caller, to_reply(results)
      _ ->
        :ok
    end
  end
  def where_is(_caller, _address), do: :ok

  def to_reply(%{"results" => results}) when is_list(results) and length(results) > 0 do
    result = hd(results)
    location = "#{result["geometry"]["location"]["lat"]},#{result["geometry"]["location"]["lng"]}"
    "That's somewhere around #{location} - https://maps.google.com/maps?q=#{location}"
  end
  def to_reply(), do: "No idea. Tried using a map? https://maps.google.com/"

  def fetch_address_cached(address) when is_binary(address) do
    case Brokk.Brain.lookup({:where_is, address}) do
      {:ok, cached} ->
        {:ok, cached}
      _ ->
        fetch_address(address)
    end
  end

  def fetch_address(address) when is_binary(address) do
    Logger.debug "Trying to resolve #{address}"
    case HTTPoison.get("https://maps.googleapis.com/maps/api/geocode/json", [], params: %{address: address}) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        results =
          body
          |> String.strip
          |> Poison.decode!
        Brokk.Brain.update {:where_is, address}, results
        {:ok, results}
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.debug "Unable to fetch location #{inspect address}, for reason #{inspect reason}"
        {:error, reason}
      _any ->
        {:error, :unknown}
    end
  end

end