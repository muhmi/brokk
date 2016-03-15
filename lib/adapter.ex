defmodule Brokk.Adapter do

  use Behaviour

  @callback child_spec :: Supervisor.spec

end