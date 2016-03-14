defmodule Brokk.Brain.ETS.Supervisor do
  use Supervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = []

    :ets.new(:brokk_brain,  [:set, :named_table, :public, read_concurrency: true])

    supervise(children, strategy: :one_for_one)
  end
end

defmodule Brokk.Brain.ETS do

  @behaviour Brokk.Brain

  def lookup(key) do
    case :ets.lookup(:brokk_brain, key) do
      [] ->
        {:error, :not_found}
      [{_key, value}] ->
        {:ok, value}
    end
  end

  def update(key, value) do
    true = :ets.insert(:brokk_brain, {key, value})
    :ok
  end

  def delete(key) do
    case :ets.delete(:brokk_brain, key) do
      {:error, :key_enoent} ->
        :ok
      _ ->
        :ok
    end
  end

  def child_spec do
    import Supervisor.Spec, warn: false
    supervisor(Brokk.Brain.ETS.Supervisor, [[name: Brokk.Brain.ETS.Supervisor]])
  end

end
