defmodule Tabebuia.ParserTest do
  use ExUnit.Case, async: true

  alias Tabebuia.Parser
  alias Tabebuia.Header

  setup do
    # Create a simple tar archive in memory for testing
    file_header = Header.for_file("test.txt", 13)
    file_content = "Hello, World!"
    dir_header = Header.for_directory("mydir/")
    
    archive_data = 
      Header.encode(file_header) <> 
      String.pad_trailing(file_content, ceil(byte_size(file_content) / 512) * 512, <<0>>) <>
      Header.encode(dir_header) <>
      <<0::size(1024*8)>>  # Two zero blocks for end
    
    %{archive_data: archive_data, file_content: file_content}
  end

  describe "parse_archive/1" do
    test "parses a valid archive", %{archive_data: archive_data, file_content: file_content} do
      assert {:ok, entries} = Parser.parse_archive(archive_data)
      assert length(entries) == 2
      
      # Check file entry
      {file_header, file_data} = Enum.at(entries, 0)
      assert file_header.name == "test.txt"
      assert file_data == file_content
      
      # Check directory entry
      {dir_header, dir_data} = Enum.at(entries, 1)
      assert dir_header.name == "mydir/"
      assert dir_data == ""
    end

    test "returns empty list for archive with only end markers" do
      end_archive = <<0::size(1024*8)>>
      assert {:ok, []} = Parser.parse_archive(end_archive)
    end

    test "returns empty for truncated archive" do
      truncated = <<0::size(256*8)>>  # Less than a full block
      assert {:ok, []} = Parser.parse_archive(truncated)
    end

    test "handles archive with no end markers gracefully" do
      # Create archive without end markers
      header = Header.for_file("test.txt", 0)
      archive_data = Header.encode(header)
      
      assert {:ok, [_entry]} = Parser.parse_archive(archive_data)
    end
  end
end
