defmodule BrainTest do
  use ExUnit.Case, async: false

  test "not found" do
    assert {:error, :not_found} = Brokk.Brain.lookup(:yo_mama)
  after
    Brokk.Brain.delete(:yo_mama)
  end

  test "found" do
    assert :ok == Brokk.Brain.update(:yo_mama, "foo")
    assert {:ok, "foo"} == Brokk.Brain.lookup(:yo_mama)
  after
    Brokk.Brain.delete(:yo_mama)
  end

  test "complex data" do
    map = %{foo: %{count: 5}}
    assert :ok == Brokk.Brain.update(:yo_mama, map)
    {:ok, res} = Brokk.Brain.lookup(:yo_mama)

    assert res.foo.count == map.foo.count
  after
    Brokk.Brain.delete(:yo_mama)
  end

end
