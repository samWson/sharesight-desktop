defmodule SharesightDesktop.Server do
  use GenServer

  @impl GenServer
  def init(_) do
    {:wx_ref, _, _, pid} = SharesightDesktop.start_link()
    ref = Process.monitor(pid)

    {:ok, {ref, pid}}
  end

  @impl GenServer
  def handle_info({:DOWN, _, _, _, _}, _state) do
    System.stop(0)

    {:stop, :ignore, nil}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, [])
  end
end