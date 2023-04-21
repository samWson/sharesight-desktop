defmodule SharesightDesktop do
  @behaviour :wx_object

  @title "Sharesight Desktop"
  @size {600, 600}

  def start_link() do
    :wx_object.start_link(__MODULE__, [], [])
  end

  def init(_args \\ []) do
    wx = :wx.new()

    frame_id = next_id_number()
    frame = :wxFrame.new(wx, frame_id, @title, size: @size)
    :wxFrame.connect(frame, :close_window)

    :wxFrame.show(frame)

    state = %{frame: frame}

    {frame, state}
  end

  def handle_event({:wx, _, _, _, {:wxClose, :close_window}}, state) do
    {:stop, :normal, state}
  end

  defp next_id_number() do
    System.unique_integer([:positive, :monotonic])
  end
end
