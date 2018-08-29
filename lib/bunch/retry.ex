defmodule Bunch.Retry do
  @moduledoc """
  A bunch of helpers for handling scenarios when some actions should be repeated
  until it succeeds.
  """

  @type retry_option ::
          {:times, non_neg_integer()}
          | {:duration, milliseconds :: pos_integer}
          | {:delay, milliseconds :: pos_integer}

  @doc """
  Calls `fun` function until `arbiter` function decides to stop.
  """
  @spec retry(
          fun :: (() -> res),
          arbiter :: (res -> :retry | :finish),
          params :: [retry_option()]
        ) :: res
        when res: any()
  def retry(fun, arbiter, params) do
    times = params |> Keyword.get(:times, :infinity)
    duration = params |> Keyword.get(:duration, :infinity)
    delay = params |> Keyword.get(:delay, 0)
    fun |> do_retry(arbiter, times, duration, delay, 0, System.monotonic_time(:milliseconds))
  end

  defp do_retry(fun, arbiter, times, duration, delay, retries, init_time) do
    ret = fun.()

    case arbiter.(ret) do
      :finish ->
        ret

      :retry ->
        cond do
          times |> infOrGt(retries) &&
              duration |> infOrGt(System.monotonic_time(:milliseconds) - init_time + delay) ->
            :timer.sleep(delay)
            fun |> do_retry(arbiter, times, duration, delay, retries + 1, init_time)

          true ->
            ret
        end
    end
  end

  defp infOrGt(:infinity, _), do: true
  defp infOrGt(val, other), do: val > other
end
