defmodule Todo.List do
  defstruct next_id: 1, entries: %{}

  def new(entries \\ []) do
    Enum.reduce(
      entries,
      %Todo.List{},
      fn entry, todo_list_acc ->
        add_entry(todo_list_acc, entry)
      end
    )
  end

  def add_entry(todo_list, entry) do
    entry = Map.put(entry, :id, todo_list.next_id)

    new_entries =
      Map.put(
        todo_list.entries,
        todo_list.next_id,
        entry
      )

    %Todo.List{todo_list | entries: new_entries, next_id: todo_list.next_id + 1}
  end

  def update_entry(todo_list, entry_id, updater_fun) do
    case Map.fetch(todo_list.entries, entry_id) do
      :error ->
        todo_list

      {:ok, old_entry} ->
        new_entry = updater_fun.(old_entry)
        new_entries = Map.put(todo_list.entries, new_entry.id, new_entry)
        %Todo.List{todo_list | entries: new_entries}
    end
  end

  def delete_entry(todo_list, entry_id) do
    new_entries = Map.delete(todo_list.entries, entry_id)
    %Todo.List{todo_list | entries: new_entries}
  end

  def entries(todo_list, date) do
    todo_list.entries
    |> Map.values()
    |> Enum.filter(fn entry -> entry.date == date end)
  end
end

defmodule Todo.List.CsvImporter do
  def import(path) do
    File.stream!(path)
    |> Stream.map(&String.trim_trailing(&1, "\n"))
    |> Stream.map(fn entry ->
      [date_string, title] = String.split(entry, ",")
      date = Date.from_iso8601!(date_string)
      %{date: date, title: title}
    end)
    |> Todo.List.new()
  end
end

defimpl String.Chars, for: Todo.List do
  def to_string(_) do
    "#Todo.List"
  end
end

defimpl Collectable, for: Todo.List do
  def into(original) do
    {original, &into_callback/2}
  end

  def into_callback(todo_list, {:cont, entry}) do
    Todo.List.add_entry(todo_list, entry)
  end

  def into_callback(todo_list, :done) do
    todo_list
  end

  def into_callback(_todo_list, :halt) do
    :ok
  end
end
