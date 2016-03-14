defprotocol Brokk.Brain.Encoder do
  @fallback_to_any true
  @spec encode(any()) :: binary()
  def encode(data)
end

defprotocol Brokk.Brain.Decoder do
  @fallback_to_any true
  @spec decode(binary()) :: any()
  def decode(data)
end

defimpl Brokk.Brain.Encoder, for: Any do
  @spec encode(any()) :: binary()
  def encode(data), do: :erlang.term_to_binary(data)
end

defimpl Brokk.Brain.Decoder, for: Any do
  @spec decode(binary()) :: any()
  def decode(data), do: :erlang.binary_to_term(data)
end

defmodule Brokk.Brain do

  use Behaviour

  defmacro is_key(thing) do
    quote do: is_atom(unquote(thing)) or is_binary(unquote(thing)) or is_tuple(unquote(thing))
  end

  @type key :: atom | binary | {atom, binary()}

  @callback lookup(key) :: {:ok, Brokk.Brain.Data.t} | {:error, :not_found}

  @callback update(key, data :: Brokk.Brain.Data.t) :: :ok

  @callback delete(key) :: :ok

  @callback child_spec :: Supervisor.spec

  def lookup(key) when is_key(key) do
    case impl.lookup(key) do
      {:ok, binary} ->
        {:ok, Brokk.Brain.Decoder.decode(binary)}
      any ->
        any
    end
  end

  def update(key, data) when is_key(key) do
    impl.update(key, Brokk.Brain.Encoder.encode(data))
  end

  def delete(key) when is_key(key) do
    impl.delete(key)
  end

  def child_spec do
    impl.child_spec
  end

  def impl do
    Application.get_env(:brokk, :brain, Brokk.Brain.ETS)
  end

end