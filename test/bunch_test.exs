defmodule BunchTest do
  use Bunch
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  @module Bunch

  doctest @module

  test "withl warns on redundant else labels" do
    warns =
      capture_io(:stderr, fn ->
        quote do
          withl a: _a <- 123,
                b: _a = 123 do
            :ok
          else
            a: _a -> :error
            b: _b -> :error
            c: _c -> :error
          end
        end
        |> Code.compile_quoted()
      end)

    refute String.contains?(warns, "withl's else clause labelled :a will never match")
    assert String.contains?(warns, "withl's else clause labelled :b will never match")
    assert String.contains?(warns, "withl's else clause labelled :c will never match")
  end
end
