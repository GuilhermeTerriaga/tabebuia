defmodule Tabebuia.HeaderTest do
  use ExUnit.Case, async: true

  alias Tabebuia.Header

  describe "for_file/3" do
    test "creates a file header with correct defaults" do
      header = Header.for_file("test.txt", 1024)
      
      assert header.name == "test.txt"
      assert header.size == 1024
      assert header.typeflag == "0"
      assert header.mode == 0o644
      assert is_integer(header.mtime)
      assert header.mtime > 0
    end

    test "accepts custom mtime" do
      mtime = 1_234_567_890
      header = Header.for_file("test.txt", 1024, mtime)
      
      assert header.mtime == mtime
    end
  end

  describe "for_directory/2" do
    test "creates a directory header with trailing slash" do
      header = Header.for_directory("mydir")
      
      assert header.name == "mydir/"
      assert header.size == 0
      assert header.typeflag == "5"
      assert header.mode == 0o755
    end

    test "keeps existing trailing slash" do
      header = Header.for_directory("mydir/")
      
      assert header.name == "mydir/"
    end
  end

  describe "encode/1 and decode/1" do
    test "encodes and decodes a file header correctly" do
      original = Header.for_file("test.txt", 1234, 1_234_567_890)
      encoded = Header.encode(original)
      
      assert byte_size(encoded) == 512
      
      # Test decode
      assert {:ok, decoded} = Header.decode(encoded)
      
      assert decoded.name == original.name
      assert decoded.size == original.size
      assert decoded.mtime == original.mtime
      assert decoded.typeflag == original.typeflag
    end

    test "encodes and decodes a directory header correctly" do
      original = Header.for_directory("mydir", 1_234_567_890)
      encoded = Header.encode(original)
      
      assert byte_size(encoded) == 512
      
      assert {:ok, decoded} = Header.decode(encoded)
      
      assert decoded.name == original.name
      assert decoded.size == original.size
      assert decoded.typeflag == original.typeflag
    end

    test "handles empty file correctly" do
      original = Header.for_file("empty.txt", 0)
      encoded = Header.encode(original)
      
      assert {:ok, decoded} = Header.decode(encoded)
      assert decoded.size == 0
    end

    test "decodes end marker" do
      end_block = <<0::size(512*8)>>
      assert {:end, nil} = Header.decode(end_block)
    end

    test "returns error for invalid block size" do
      invalid_block = <<0::size(100*8)>>
      assert {:error, :invalid_block_size} = Header.decode(invalid_block)
    end

    test "handles long filenames" do
      long_name = String.duplicate("a", 100)
      original = Header.for_file(long_name, 100)
      encoded = Header.encode(original)
      
      assert {:ok, decoded} = Header.decode(encoded)
      assert decoded.name == long_name
    end
  end

  describe "full_name/1" do
    test "returns just name when no prefix" do
      header = %Header{name: "file.txt", prefix: ""}
      assert Header.full_name(header) == "file.txt"
    end

    test "joins prefix and name when prefix exists" do
      header = %Header{name: "file.txt", prefix: "path/to"}
      assert Header.full_name(header) == "path/to/file.txt"
    end
  end
end
