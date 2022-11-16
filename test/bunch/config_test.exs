defmodule Bunch.ConfigTest do
  use ExUnit.Case, async: true

  @module Bunch.Config

  doctest @module

  test "config parsing" do
    assert {:error, {:config_field, {:key_not_found, :c}}} ==
             @module.parse(
               [a: 1, b: 1],
               a: [validate: &(&1 > 0)],
               b: [in: -2..2],
               c: []
             )

    assert {:error, {:config_invalid_keys, [:c, :d]}} ==
             @module.parse(
               [a: 1, b: 1, c: 2, d: 3],
               a: [validate: &(&1 > 0)],
               b: [in: -2..2],
               c: &if(&1.a != &1.b, do: [])
             )
  end
end
