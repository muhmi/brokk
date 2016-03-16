defmodule Brokk.Plugins.Jenkins do

  use Brokk.Plugin

  require Logger

  def on_message(_from, {:text, "/jenkins list"}) do
    {:reply, list_jobs}
  end
  def on_message(_from, _any), do: :noreply

  def list_jobs do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get! "#{jenkins_url}/api/json", [], [hackney: [basic_auth: auth]]

    response =
      body
      |> Poison.decode!

    list =
      response["jobs"]
      |> Enum.map(fn job ->
        "\t - #{job["name"]}"
      end)
    "\tJobs on #{response["nodeDescription"]}:\n#{Enum.join(list, "\n")}\n"
  end

  def jenkins_url do
    env[:url]
  end

  def auth do
    parse_auth(env[:auth])
  end
  def parse_auth(auth_string) when is_binary(auth_string) do
    parse_auth(String.split(auth_string, ":"))
  end
  def parse_auth([user, token]) do
    {user, token}
  end
  def parse_auth(wat) do
    Logger.error "Unable to parse auth token for Jenkins API access from #{inspect wat}"
  end

  def env do
    Application.get_env(:brokk, :jenkins)
  end

end