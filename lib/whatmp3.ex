defmodule Whatmp3 do
  @doc """
  Parse an mp3 file and return its ID3 tag data.
  """
  def parse(file_name) do
    case File.read(file_name) do
      {:ok, binary} ->
        # ID3 tag is in the last 128 bytes of an MP3 file, so here we calculate the size of the
        # audio part of the file.
        mp3_byte_size = (byte_size(binary) - 128)

        # Pattern matching on binary to destructure the binary based on the size of the bytes.
        # The first part is the audio part which we don't care about (hence the underscore).
        # Here we specify the size for the first part, but omit it from the end part because
        # we just grab whatever is left after discarding the audio part.
        << _ :: binary-size(mp3_byte_size), id3_tag :: binary >> = binary

        # First 3 bytes of the id3_tag is just TAG, after which the respective sizes of each
        # field in the layout are matched by binary-size. As each character in TAG is a byte,
        # we don't need to specify a size for it here.
        << "TAG",
        id3_title    :: binary-size(30),
        id3_artist   :: binary-size(30),
        id3_album    :: binary-size(30),
        id3_year     :: binary-size(4),
        _id3_comment :: binary-size(30),
        _rest        :: binary >> = id3_tag

        # Trim unprintable characters from id3 tag data
        [title, artist, album, year] = trim_unprintable([id3_title, id3_artist, id3_album, id3_year])

        # Output results
        IO.puts "#{artist} - #{title} (#{album}, #{year})"

      _ ->
        IO.puts "Couldn't open #{file_name}"
    end
  end

  # Trims unprintable characters from strings by chunking strings by printable and
  # unprintable characters, and returning just the printable ones.
  defp trim_unprintable([string | rest]) do
    [trim_unprintable(string) | trim_unprintable(rest)]
  end
  defp trim_unprintable([]), do: []
  defp trim_unprintable(string) do
    trimmed = string
    |> String.chunk(:printable)
    |> List.first

    # Check if the trimmed string looks good. Done because sometimes we might end up
    # having no printable characters at all (e.g. empty field), in which case the first
    # value returned would still be unprintable.
    case String.printable?(trimmed) do
      false -> ""
      true -> trimmed
    end
  end
end
