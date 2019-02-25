defmodule Bunch.Process do
  @moduledoc """
  A bunch of functions extending functionality of the `Process` module.
  """

  @doc """
  Sends message when system time reaches given amount of milliseconds.

  Works the same way as `Process.send_after/4` with `abs` option set to `true`,
  but accepts time expressed in milliseconds and as OS time instead of monotonic
  time.

  Calls `Process.send_after/3` under the hood and returns reference that can
  be managed by other functions from that module, such as `Process.cancel_timer/1`
  """
  @spec send_at(pos_integer, pid, any) :: reference
  def send_at(time, pid \\ self(), msg) do
    Process.send_after(pid, msg, time - System.os_time(:millisecond))
  end
end
