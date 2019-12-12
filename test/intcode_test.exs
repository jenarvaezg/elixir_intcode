defmodule IntcodeTest do
  use ExUnit.Case
  doctest Intcode

  defp code(day) do
    File.read!("test/inputs/#{day}_input.txt")
    |> String.split(",")
    |> Enum.map(&String.to_integer/1)
  end

  test "output input and halt" do
    input = :rand.uniform(10000)

    {program, output, :cont} = [3,0,4,0,99]
    |> Intcode.new()
    |> Intcode.push_input(input)
    |> Intcode.run_until_output

    assert input == output

    {_program, nil, :halt} = Intcode.run_until_output(program)
  end

  test "simple immediate halts" do
    {_program, nil, :halt} = [1002,4,3,4,33]
    |> Intcode.new()
    |> Intcode.run_until_output
  end

  test "day 2 part 1" do
    {program, nil, :halt} = code("day_2")
    |> (fn code ->
      List.replace_at(code, 1, 12) |> List.replace_at(2, 2)
    end).()
    |> Intcode.new()
    |> Intcode.run_until_output

    assert 3058646 == Map.get(program.memory, 0)
  end

  test "day 2 part 2" do
    {program, nil, :halt} = code("day_2")
    |> (fn code ->
      List.replace_at(code, 1, 89) |> List.replace_at(2, 76)
    end).()
    |> Intcode.new()
    |> Intcode.run_until_output

    assert 19690720 == Map.get(program.memory, 0)
  end

  test "day 5 complex example" do
    code = [3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,
    1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,
    999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99]

    [1000] = Intcode.new(code)
    |> Intcode.push_input(8)
    |> Intcode.run_until_halt()

    [999] = Intcode.new(code)
    |> Intcode.push_input(:rand.uniform(7))
    |> Intcode.run_until_halt()

    [1001] = Intcode.new(code)
    |> Intcode.push_input(:rand.uniform(100) + 8)
    |> Intcode.run_until_halt()
  end

  test "day 5 part 1" do
    program = code("day_5")
    |> Intcode.new
    |> Intcode.push_input(1)

    outputs = Intcode.run_until_halt(program)

    assert [0, 0, 0, 0, 0, 0, 0, 0, 0, 14522484] == outputs
  end

  test "day 5 part 2" do
    outputs = code("day_5")
    |> Intcode.new
    |> Intcode.push_input(5)
    |> Intcode.run_until_halt

    assert [4655956] == outputs
  end

  test "day 9 example 1" do
    code = [109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99]

    ^code = Intcode.new(code) |> Intcode.run_until_halt
  end

  test "day 9 example 2" do
    code = [1102,34915192,34915192,7,4,7,99,0]

    [output] = Intcode.new(code) |> Intcode.run_until_halt

    assert 16 == Integer.to_string(output) |> String.length
  end

  test "day 9 example 3" do
    code = [104,1125899906842624,99]

    [1125899906842624] = Intcode.new(code) |> Intcode.run_until_halt
  end

  test "day 9 part 1" do
    [3100786347] = code("day_9")
    |> Intcode.new
    |> Intcode.push_input(1)
    |> Intcode.run_until_halt
  end

  test "day 9 part 2" do
    {ms, [87023]} = :timer.tc(fn ->
      code("day_9")
      |> Intcode.new
      |> Intcode.push_input(2)
      |> Intcode.run_until_halt
    end)

    assert ms < 300_000
  end

end
