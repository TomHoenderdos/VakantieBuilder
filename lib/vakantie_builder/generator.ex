defmodule VakantieBuilder.Generator do
  alias VakantieBuilder.DutchGovernmentHolidays

  def run(year) do
    vacation_dates = DutchGovernmentHolidays.get!(year).body

    first_day_of_school =
      vacation_dates
      |> List.flatten()
      |> List.first()
      |> Map.get(:year)
      |> first_day_of_school_year()

    weeks = generate_weeks(first_day_of_school, vacation_dates)
    events = generate_ical_events(weeks)

    ics =
      %ICalendar{events: events}
      |> ICalendar.to_ics()

    File.write!("week_days_for_#{year}.ics", ics)
    IO.puts("File week_days_for_#{year}.ics written")
  end

  def generate_weeks(first_day, vacation_days) do
    periods_with_weeks = generate_periods_with_weeks()

    Enum.reduce(periods_with_weeks, [first_day], fn _period_with_week,
                                                    [prev_week_day | _] = acc ->
      [return_valid_week(prev_week_day, vacation_days)] ++ acc
    end)
    |> Enum.reverse()
    |> Enum.zip(periods_with_weeks)
  end

  def generate_ical_events(weeks) do
    Enum.map(weeks, fn {day, week_number} ->
      week_number_text = week_number_to_text(week_number)

      %ICalendar.Event{
        summary: week_number_text,
        dtstart: day,
        dtend: day,
        description: "Week #{week_number_text}"
      }
    end)
  end

  defp week_number_to_text([period_nr, week_nr]), do: "#{period_nr}.#{week_nr}"

  @amount_of_periods 4
  @amount_of_weeks_per_period 10
  defp generate_periods_with_weeks() do
    Enum.reduce(Range.new(1, @amount_of_periods), [], fn period_nr, acc ->
      acc ++
        Enum.map(Range.new(1, @amount_of_weeks_per_period), fn week_nr ->
          [period_nr, week_nr]
        end)
    end)
  end

  defp return_valid_week(prev_week_day, vacation_days) do
    week_day = Date.add(prev_week_day, 7)

    if in_vacation?(week_day, vacation_days) do
      return_valid_week(week_day, vacation_days)
    else
      week_day
    end
  end

  defp in_vacation?(day_in_week, vacation_days) do
    Enum.any?(vacation_days, fn [first_day, last_day] ->
      day_in_week in Date.range(first_day, last_day)
    end)
  end

  defp first_day_of_school_year(2023), do: Date.new!(2023, 08, 28)
  defp first_day_of_school_year(2024), do: Date.new!(2023, 09, 02)
end
