defmodule Brokk.Plugins.Jenkins do

  use Brokk.Plugin

  require Logger

  def on_message(from, {:text, "/j list"}) do
    list_jobs(from)
    :halt
  end
  def on_message(from, {:text, "/jenkins list"}) do
    list_jobs(from)
    :halt
  end
  def on_message(from, {:text, "/j desc " <> id}) do
    describe_job(from, id)
    :halt
  end
  def on_message(from, {:text, "/jenkins desc " <> id}) do
    describe_job(from, id)
    :halt
  end
  def on_message(from, {:text, "/j build " <> id}) do
    start_build(from, id)
    :halt
  end
  def on_message(from, {:text, "/jenkins build " <> id}) do
    start_build(from, id)
    :halt
  end
  def on_message(_from, _any), do: :noreply

  @doc "Ask Jenkins for a jobs description and status"
  def describe_job(caller, id) when is_binary(id) do
    spawn fn ->
      case find_job(id) do
        {:ok, job} ->
          response = api_describe_job! job["name"]
          Brokk.reply caller, to_job_description(response)
        _ ->
          Brokk.reply caller, "Hmm, I cant find a job with id/name like #{inspect id}"
      end
    end
  end

  @doc "Start a build"
  def start_build(caller, job_id) when is_binary(job_id) do
    spawn fn ->
      case find_job(job_id) do
        {:ok, job} ->
          {status, resp} = api_build_job! job["name"]
          if status >= 200 and status <= 400 do
            Brokk.reply caller, "#{status} Build started for job #{job["name"]}"
          else
            Brokk.reply caller, "Cannot start build, Jenkins says: (#{status}) #{resp}"
          end
        _ ->
          Brokk.reply caller, "Hmm, I cant find a job with id/name like #{inspect job_id}"
      end
    end
  end

  @doc "Asynchronously fetch list of jobs for caller"
  def list_jobs(caller) do
    spawn fn ->
      Brokk.reply caller, list_jobs!
    end
  end

  @doc "Synchronoys call to get a list of Jenkins jobs"
  def list_jobs! do
    response = api_get_description!
    list =
      response["jobs"]
      |> Enum.map(fn job ->
        "\t - #{job["id"]} #{job["name"]}"
      end)
    "\tJobs on #{response["nodeDescription"]}:\n#{Enum.join(list, "\n")}\n"
  end

  # API Calls

  def find_job(id) when is_binary(id) do
    case Integer.parse(id) do
      {ival, ""} -> find_job({:by_id, ival})
      str -> find_job({:by_name, str})
    end
  end

  def find_job({:by_id, id}) do
    response = api_get_description!
    job = Enum.find(response["jobs"], fn job -> job["id"] == id end)
    if job != nil do
      {:ok, job}
    else
      {:error, :not_found}
    end
  end

  def find_job({:by_name, id}) do
    response = api_get_description!
    job = Enum.find(response["jobs"], fn job -> String.starts_with?(job["name"], id) end)
    if job != nil do
      {:ok, job}
    else
      {:error, :not_found}
    end
  end

  def api_get_description! do
    response = api_request! "/api/json"

    # Insert a id for each job since Jenkins does not provide one...

    jobs = Enum.map(Enum.with_index(response["jobs"]), fn {job, index} ->
      Map.put(job, "id", index)
    end)

    Map.put(response, "jobs", jobs)
  end

  def api_describe_job!(name) when is_binary(name) do
    api_request! "/job/#{name}/api/json"
  end

  def api_last_build!(name, number) do
    api_request! "/job/#{name}/#{number}/api/json"
  end

  def api_build_job!(name) do
    %HTTPoison.Response{body: body, status_code: status} = HTTPoison.post!("#{jenkins_url}/job/#{name}/build", [], [], [hackney: [basic_auth: auth]])
    {status, body}
  end

  def api_request!(path) when is_binary(path) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get! "#{jenkins_url}#{path}", [], [hackney: [basic_auth: auth]]
    Logger.debug "Jenkins API request: #{path} -> #{body}"
    body |> Poison.decode!
  end

  def to_job_description(%{} = response) do
    health =
      if Map.has_key?(response, "healthReport") do
        Enum.map(response["healthReport"], fn report -> "     - #{report["description"]}\n" end)
      else
        "unknown"
      end

    last_build =
      if Map.has_key?(response, "lastBuild") do
        build_response = api_last_build! response["displayName"], response["lastBuild"]["number"]
        status = build_response["result"] || "PENDING"
        "    LAST JOB: #{status} #{build_response["timestamp"]}"
      else
        ""
      end

    description = "
  JOB: #{response["displayName"]}
  URL: #{response["url"]}
  HEALTH:
#{health}
"
  end

  def jenkins_url do
    env[:url]
  end

  def auth do
    parse_auth(env[:auth])
  end

  @doc "Parse 'user:token' string to {user, token} tuple"
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