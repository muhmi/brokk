defmodule Brokk.Guards do

  @doc "Guard macro for identifying valid sender types"
  defmacro is_sender(thing) do
    quote do: is_atom(unquote(thing)) or is_pid(unquote(thing))
  end

end