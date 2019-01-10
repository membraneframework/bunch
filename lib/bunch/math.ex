defmodule Bunch.Math do
  @moduledoc """
  A bunch of math helper functions.
  """

  @doc """
  Works like `div/2`, but compensates division error when it reaches 1.

  When there is some period (e.g. of time) calculated as `divident / divisor`
  that has to be integer, but integer division introduces an error, this error
  grows each time the period passes. This function accumulates the error
  and periodically adds compensating component to the result.

  Returned value is a tuple consisting of result and updated error. This error
  needs to be passed to subsequent call of the function. Initial error should be
  set to 0. `error` represents error relatively to the divisor (real error can
  be expressed as `error / divisor`), thus error is valid only for the same
  divisor.

  ## Example

      iex> 1..10 |> Enum.map_reduce(0, fn _, err -> #{inspect(__MODULE__)}.div_err(9, 4, err) end)
      {[2, 2, 2, 3, 2, 2, 2, 3, 2, 2], 2}

  """
  @spec div_err(divident :: non_neg_integer, divisor :: pos_integer, error :: non_neg_integer) ::
          {result :: non_neg_integer, error :: non_neg_integer}
  def div_err(dividend, divisor, error \\ 0) when error < divisor do
    error = error + rem(dividend, divisor)

    if error < divisor do
      {div(dividend, divisor), error}
    else
      {div(dividend, divisor) + 1, error - divisor}
    end
  end
end
