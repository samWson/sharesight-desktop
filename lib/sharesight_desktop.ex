defmodule SharesightDesktop do
  @behaviour :wx_object

  @button_label "GET"
  @multiline 0x0020 # wxTE_MULTILINE
  @size {600, 600}
  @title "Sharesight Desktop"

  def start_link() do
    :wx_object.start_link(__MODULE__, [], [])
  end

  def init(_args \\ []) do
    wx = :wx.new()

    frame_id = next_id_number()
    frame = :wxFrame.new(wx, frame_id, @title, size: @size)
    :wxFrame.connect(frame, :close_window)

    panel = :wxPanel.new(frame)

    url_text_id = next_id_number()
    url_text = :wxTextCtrl.new(panel, url_text_id, size: {300, -1})

    button_id = next_id_number()
    button = :wxButton.new(panel, button_id, label: @button_label, pos: {0, 32})
    :wxButton.connect(button, :command_button_clicked)

    body_text_id = next_id_number()
    body_text = :wxTextCtrl.new(
      panel,
      body_text_id,
      pos: {0, 64},
      style: @multiline,
      size: {400, 400}
      )

    :wxFrame.show(frame)

    state = %{frame: frame, url_text: url_text, body_text: body_text}

    {frame, state}
  end

  def handle_event({:wx, _, _, _, {:wxClose, :close_window}}, state) do
    {:stop, :normal, state}
  end

  def handle_event(
    {
      :wx,
      _,
      {:wx_ref, _, :wxButton, _},
      _,
      {:wxCommand, :command_button_clicked, _, _, _}
    },
    state) do
    url = :wxTextCtrl.getLineText(state.url_text, 0)

    :wxTextCtrl.clear(state.body_text)
    :wxTextCtrl.setInsertionPoint(state.body_text, 0)
    :wxTextCtrl.writeText(state.body_text, url)

    {:noreply, state}
  end

  defp next_id_number() do
    System.unique_integer([:positive, :monotonic])
  end
end
