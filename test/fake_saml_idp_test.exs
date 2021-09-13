defmodule FakeSamlIdpTest do
  use ExUnit.Case
  doctest FakeSamlIdp

  test "greets the world" do
    assert FakeSamlIdp.hello() == :world
  end
end
