defmodule BrokkTest do
  use ExUnit.Case
  doctest Brokk

  test "one plugin consumes message" do
    msg = {:msg, self, {:text, "/echo Hello World!"}}
    plugins = [Brokk.Plugins.Echo]
    assert {:halt, Brokk.Plugins.Echo} == Brokk.Worker.call_plugins(msg, plugins)

    # should get a reply back
    assert_received {:text, "Hello World!"}
  end

  test "multiple plugins" do
    msg = {:msg, self, {:text, "Hello World!"}}
    plugins = [
      Brokk.Plugins.NoOp,
      Brokk.Plugins.NoOp,
      Brokk.Plugins.Consume
    ]
    assert {:halt, Brokk.Plugins.Consume} == Brokk.Worker.call_plugins(msg, plugins)
  end

  test "echo, but no receiver" do
    msg = {:msg, :cant_reply_to_atom, {:text, "/echo Hello World!"}}
    plugins = [
      Brokk.Plugins.NoOp,
      Brokk.Plugins.NoOp,
      Brokk.Plugins.Echo,
      Brokk.Plugins.Explode
    ]
    assert {:halt, Brokk.Plugins.Echo} == Brokk.Worker.call_plugins(msg, plugins)
  end

  test "lastlog" do
    plugins = [
      Brokk.Plugins.NoOp,
      Brokk.Plugins.NoOp,
      Brokk.Plugins.LastLog,
      Brokk.Plugins.Consume
    ]
    for n <- 1..10 do
      msg = {:msg, :cant_reply_to_atom, {:text, "Logged line #{n}"}}
      assert {:halt, Brokk.Plugins.Consume} == Brokk.Worker.call_plugins(msg, plugins)
    end

    log = Brokk.Plugins.LastLog.get_log

    assert length(log) == 10
  end

end
