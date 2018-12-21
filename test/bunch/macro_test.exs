defmodule Bunch.MacroTest do
  use ExUnit.Case, async: true

  @module Bunch.Macro

  doctest @module
end
