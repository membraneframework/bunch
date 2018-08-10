defmodule Bunch.BitstringSpec do
  use ESpec, async: true

  # These functions just wraps result of sample function used for specs in
  # the `{:ok, something}` return value.
  def sample_fun_upcase_ok_with_value(bitstring) do
    {:ok, String.upcase(bitstring)}
  end

  def sample_fun_upcase_ok_without_value(_bitstring) do
    :ok
  end

  def sample_fun_equivalent_ok_with_value?(bitstring1, bitstring2) do
    {:ok, String.equivalent?(bitstring1, bitstring2)}
  end

  def sample_fun_equivalent_ok_without_value?(_bitstring1, _bitstring2) do
    :ok
  end

  # These functions just wraps result of sample function used for specs in
  # the `{:error, something}` return value.
  def sample_fun_upcase_error_with_value("ab") do
    {:error, :something}
  end

  def sample_fun_upcase_error_with_value(bitstring) do
    {:ok, String.upcase(bitstring)}
  end

  def sample_fun_upcase_error_without_value("ab") do
    {:error, :something}
  end

  def sample_fun_upcase_error_without_value(_bitstring) do
    :ok
  end

  describe ".split/2" do
    let :data, do: "abcd"

    context "if length is an integer multiplication of chunk_size" do
      it "should split data into chunks" do
        expect(described_module().split(data(), 2)) |> to(eq {["ab", "cd"], <<>>})
      end
    end

    context "if length is not an integer multiplication of chunk_size" do
      it "should split data into chunks and store the rest" do
        expect(described_module().split(data(), 3)) |> to(eq {["abc"], "d"})
      end
    end
  end

  describe ".split!/2" do
    let :data, do: "abcd"

    context "if length is an integer multiplication of chunk_size" do
      it "should split data into chunks" do
        expect(described_module().split!(data(), 2)) |> to(eq ["ab", "cd"])
      end
    end

    context "if length is not an integer multiplication of chunk_size" do
      it "should split data into chunks and drop the rest" do
        expect(described_module().split!(data(), 3)) |> to(eq ["abc"])
      end
    end
  end
end
