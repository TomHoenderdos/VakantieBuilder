defmodule VakantieBuilder.DutchGovernmentHolidays do
  alias Timex.Date
  use HTTPoison.Base

  def process_request_url(from_year) do
    to_year = String.to_integer(from_year) + 1

    "https://www.rijksoverheid.nl/onderwerpen/schoolvakanties/overzicht-schoolvakanties-per-schooljaar/overzicht-schoolvakanties-#{from_year}-#{to_year}"
  end

  def process_response_body(body) do
    raw_vacation_dates = parse_body(body)

    raw_vacation_dates
    |> Enum.map(&parse_dates/1)
  end

  def parse_body(body) do
    body
    |> Floki.parse_document!()
    |> Floki.find("table")
    |> Floki.find("td:nth-child(3)")
  end

  def parse_dates({_, _, [date_tuple]}) when is_tuple(date_tuple), do: parse_dates(date_tuple)

  def parse_dates({_, _, [date]}) do
    [first_part, second_part] =
      date
      |> String.trim()
      |> String.split(" t/m ")

    first_date = to_date(String.split(first_part, " "), String.split(second_part, " "))
    second_date = to_date(String.split(second_part, " "))

    [first_date, second_date]
  end

  def parse_dates(_), do: ""

  defp to_date([day, month_string, year]) do
    Date.new!(String.to_integer(year), to_month_number(month_string), String.to_integer(day))
  end

  defp to_date([day, month_string, year], _) do
    Date.new!(String.to_integer(year), to_month_number(month_string), String.to_integer(day))
  end

  defp to_date([day, month_string], [_, _, year]) do
    Date.new!(String.to_integer(year), to_month_number(month_string), String.to_integer(day))
  end

  def to_month_number("januari"), do: 1
  def to_month_number("februari"), do: 2
  def to_month_number("maart"), do: 3
  def to_month_number("april"), do: 4
  def to_month_number("mei"), do: 5
  def to_month_number("juni"), do: 6
  def to_month_number("juli"), do: 7
  def to_month_number("augustus"), do: 8
  def to_month_number("september"), do: 9
  def to_month_number("oktober"), do: 10
  def to_month_number("november"), do: 11
  def to_month_number("december"), do: 12
end
