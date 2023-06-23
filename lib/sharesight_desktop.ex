defmodule SharesightDesktop do
  import Logger, only: [info: 2, warning: 2]

  @behaviour :wx_object

  @size {600, 600}
  @title "Sharesight Desktop"
  @wxAll 0xf0
  @wxLC_REPORT 0x0020
  @wxVERTICAL 0x0008

  def start_link() do
    :wx_object.start_link(__MODULE__, [], [])
  end

  def init(_args \\ []) do
    wx = :wx.new()

    sizer = :wxBoxSizer.new(@wxVERTICAL)

    sizer_flags = :wxSizerFlags.new()
    :wxSizerFlags.center(sizer_flags)
    :wxSizerFlags.border(sizer_flags, @wxAll, 5)

    frame_id = next_id_number()
    frame = :wxFrame.new(wx, frame_id, @title, size: @size)
    :wxFrame.connect(frame, :close_window)

    panel = :wxPanel.new(frame)

    table_id = next_id_number()
    table = :wxListCtrl.new(panel, winid: table_id, style: @wxLC_REPORT)
    headers = [
      "Code",
      "Price",
      "Quantity",
      "Value",
      "Capital Gains",
      "Dividends",
      "Currency",
      "Return"
    ]

    Enum.reduce(headers, 0, fn header, index ->
      :wxListCtrl.insertColumn(table, index, header)
      index + 1
    end)

    :wxSizer.add(sizer, table, sizer_flags)

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
      access_token: access_token,
      table: table
    }

    show_performance_report(state)

    {frame, state}
  end

  def handle_event({:wx, _, _, _, {:wxClose, :close_window}}, state) do
    {:stop, :normal, state}
  end

  defp next_id_number() do
    System.unique_integer([:positive, :monotonic])
  end

  defp show_performance_report(state) do
    {:ok, url} = fetch_api_url_variable()
    |> URI.new()

    body = SharesightDesktop.ApiClient.get(url, state.access_token)
    |> SharesightDesktop.ApiClient.body()

    {:ok, response} = Jason.decode(body)
    holdings = response["report"]["holdings"]

    {records, _last_index} = Enum.map_reduce(holdings, 0, fn holding, index ->
      list_item = :wxListItem.new()
      :wxListItem.setId(list_item, index)

      instrument = Map.get(holding, "instrument")

      code = "#{instrument["code"]}.#{instrument["name"]}"
      price = "#{holding["instrument_price"]}"
      quantity = "#{holding["quantity"]}"
      value = "#{holding["value"]}"
      capital_gain = "#{holding["capital_gain"]}"
      dividends = "#{holding["payout_gain"]}"
      currency = "#{holding["currency_gain"]}"
      return = "#{holding["total_gain"]}"

      item = %{
        index: index,
        list_item: list_item,
        code: code,
        price: price,
        quantity: quantity,
        value: value,
        capital_gain: capital_gain,
        dividends: dividends,
        currency: currency,
        return: return
      }

      {item, index + 1}
    end)

    Enum.each(records, fn record ->
      :wxListCtrl.insertItem(state.table, record[:list_item])
      :wxListCtrl.setItem(state.table, record[:index], 0, record[:code]) # 0 - 'Code' index
      :wxListCtrl.setItem(state.table, record[:index], 1, record[:price])
      :wxListCtrl.setItem(state.table, record[:index], 2, record[:quantity])
      :wxListCtrl.setItem(state.table, record[:index], 3, record[:value])
      :wxListCtrl.setItem(state.table, record[:index], 4, record[:capital_gain])
      :wxListCtrl.setItem(state.table, record[:index], 5, record[:dividends])
      :wxListCtrl.setItem(state.table, record[:index], 6, record[:currency])
      :wxListCtrl.setItem(state.table, record[:index], 7, record[:return])
    end)
  end

  defp fetch_api_url_variable do
    case System.fetch_env("API_URL") do
      {:ok, variable} ->
        variable
      :error ->
        Logger.warning("API_URL not fetched from the environment")
        ""
    end
  end
end
