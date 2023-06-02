defmodule SharesightDesktop do
  import Logger, only: [info: 2, warning: 2]

  @behaviour :wx_object

  @button_label "GET"
  @multiline 0x0020 # wxTE_MULTILINE
  @size {600, 600}
  @title "Sharesight Desktop"
  @wxVertical 0x0008
  @wxAll 0xf0

  def start_link() do
    :wx_object.start_link(__MODULE__, [], [])
  end

  def init(_args \\ []) do
    wx = :wx.new()

    sizer = :wxBoxSizer.new(@wxVertical)

    sizer_flags = :wxSizerFlags.new()
    :wxSizerFlags.center(sizer_flags)
    :wxSizerFlags.border(sizer_flags, @wxAll, 5)

    frame_id = next_id_number()
    frame = :wxFrame.new(wx, frame_id, @title, size: @size)
    :wxFrame.connect(frame, :close_window)

    panel = :wxPanel.new(frame)

    url_text_id = next_id_number()
    url_text = :wxTextCtrl.new(panel, url_text_id, size: {300, -1})
    :wxWindow.setFocus(url_text)

    button_id = next_id_number()
    button = :wxButton.new(panel, button_id, label: @button_label)
    :wxButton.connect(button, :command_button_clicked)

    body_text_id = next_id_number()

    body_text =
      :wxTextCtrl.new(
        panel,
        body_text_id,
        pos: {0, 64},
        style: @multiline,
        size: {400, 400}
      )

    Enum.each([url_text, button, body_text], fn window ->
      :wxSizer.add(sizer, window, sizer_flags)
    end)

    :wxWindow.setSizer(panel, sizer)

    :wxSizer.setSizeHints(sizer, frame)

    :wxFrame.show(frame)

    SharesightDesktop.ApiClient.start()

    access_token = case SharesightDesktop.ApiClient.get_access_token!() do
      {:ok, token} ->
        Logger.info("Access token retrieved")
        token
      {:error, reason} ->
        Logger.warning("Access token not retrieved: #{reason}")
        ""
    end

    state = %{
      frame: frame,
      url_text: url_text,
      body_text: body_text,
      access_token: access_token
    }

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
        state
      ) do

    url = :wxTextCtrl.getLineText(state.url_text, 0)
    |> List.to_string()
    |> String.trim()

    body = SharesightDesktop.ApiClient.get(url, state.access_token)
    |> SharesightDesktop.ApiClient.body()

    :wxTextCtrl.clear(state.body_text)
    :wxTextCtrl.setInsertionPoint(state.body_text, 0)
    :wxTextCtrl.writeText(state.body_text, body)

    {:noreply, state}
  end

  defp next_id_number() do
    System.unique_integer([:positive, :monotonic])
  end
end
