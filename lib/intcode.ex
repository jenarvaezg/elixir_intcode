defmodule Intcode do
  defstruct memory: Map.new(), execution_pointer: 0, stack_pointer: 0, input: []

  @spec new([integer]) :: Intcode.t()
  def new(code) when is_list(code) do
    memory = Enum.with_index(code) |> Map.new(fn {value, index} -> {index, value} end)

    %__MODULE__{
      memory: memory
    }
  end

  @spec push_input(Intcode.t(), [integer] | integer) :: Intcode.t()
  def push_input(%__MODULE__{} = program, input) when is_integer(input) do
    %__MODULE__{
      program | input: program.input ++ [input]
    }
  end

  def push_input(%__MODULE__{} = program, input) when is_list(input) do
    %__MODULE__{
      program | input: program.input ++ input
    }
  end


  def run_until_output(%__MODULE__{} = program) do
    case process_next_instruction(program) do
      {%__MODULE__{} = program, _, :halt} ->
        {program, nil, :halt}

      {%__MODULE__{} = program, nil, :cont} ->
        run_until_output(program)

      {%__MODULE__{} = program, output, :cont} ->
        {program, output, :cont}
    end
  end

  @spec run_until_halt(Intcode.t(), integer) :: any
  def run_until_halt(%__MODULE__{} = program, max_iterations \\ 100_000_000) do
    Enum.reduce_while(1..max_iterations, {program, []}, fn (_, {program, outputs}) ->
      case Intcode.run_until_output(program) do
        {_program, nil, :halt} -> {:halt, outputs}
        {program, output, :cont} -> {:cont, {program, outputs ++ [output]}}
      end
    end)
  end

  @spec process_next_instruction(Intcode.t()) :: {Intcode.t(), any, :cont | :halt}
  defp process_next_instruction(%__MODULE__{} = program) do
    case next_instruction(program) do
      %{opcode: 1} = instruction ->
        process_sum(instruction, program)
      %{opcode: 2} = instruction ->
        process_mul(instruction, program)
      %{opcode: 3} = instruction ->
        process_input(instruction, program)
      %{opcode: 4} = instruction ->
        process_output(instruction, program)
      %{opcode: 5} = instruction ->
        process_jump_if_true(instruction, program)
      %{opcode: 6} = instruction ->
        process_jump_if_false(instruction, program)
      %{opcode: 7} = instruction ->
        process_less_than(instruction, program)
      %{opcode: 8} = instruction ->
        process_equals(instruction, program)
      %{opcode: 9} = instruction ->
        process_move_stack_pointer(instruction, program)
      %{opcode: 99} = instruction ->
        process_halt(instruction, program)
    end
  end

  defp process_sum(%{:opcode => 1} = instruction, %__MODULE__{} = program) do
    a = get_value(program, program.execution_pointer + 1, instruction.first_mode)
    b = get_value(program, program.execution_pointer + 2, instruction.second_mode)
    target = get_address(program, program.execution_pointer + 3, instruction.third_mode)

    next_program = %Intcode{
      program
      | memory: Map.put(program.memory, target, a + b),
        execution_pointer: program.execution_pointer + 4
    }
    {next_program, nil, :cont}
  end

  defp process_mul(%{:opcode => 2} = instruction, %__MODULE__{} = program) do
    a = get_value(program, program.execution_pointer + 1, instruction.first_mode)
    b = get_value(program, program.execution_pointer + 2, instruction.second_mode)
    target = get_address(program, program.execution_pointer + 3, instruction.third_mode)

    next_program = %Intcode{
      program
      | memory: Map.put(program.memory, target, a * b),
        execution_pointer: program.execution_pointer + 4
    }

    {next_program, nil, :cont}
  end

  defp process_input(%{:opcode => 3} = instruction, %__MODULE__{} = program) do
    [value | remaining_input] = program.input
    target = get_address(program, program.execution_pointer + 1, instruction.first_mode)

    next_program = %Intcode{
      program
      | memory: Map.put(program.memory, target, value),
        execution_pointer: program.execution_pointer + 2,
        input: remaining_input
    }

    {next_program, nil, :cont}
  end

  defp process_output(%{:opcode => 4} = instruction, %__MODULE__{} = program) do
    output = get_value(program, program.execution_pointer + 1, instruction.first_mode)

    next_program = %Intcode{
      program
      | execution_pointer: program.execution_pointer + 2,
    }

    {next_program, output, :cont}
  end

  defp process_jump_if_true(%{:opcode => 5} = instruction, %__MODULE__{} = program) do
    a = get_value(program, program.execution_pointer + 1, instruction.first_mode)
    b = get_value(program, program.execution_pointer + 2, instruction.second_mode)

    next_pointer = if a != 0, do: b, else: program.execution_pointer + 3
    next_program = %Intcode{
      program
      | execution_pointer: next_pointer,
    }

    {next_program, nil, :cont}
  end

  defp process_jump_if_false(%{:opcode => 6} = instruction, %__MODULE__{} = program) do
    a = get_value(program, program.execution_pointer + 1, instruction.first_mode)
    b = get_value(program, program.execution_pointer + 2, instruction.second_mode)

    next_pointer = if a == 0, do: b, else: program.execution_pointer + 3
    next_program = %Intcode{
      program
      | execution_pointer: next_pointer,
    }

    {next_program, nil, :cont}
  end

  defp process_less_than(%{:opcode => 7} = instruction, %__MODULE__{} = program) do
    a = get_value(program, program.execution_pointer + 1, instruction.first_mode)
    b = get_value(program, program.execution_pointer + 2, instruction.second_mode)
    target = get_address(program, program.execution_pointer + 3, instruction.third_mode)

    value = if a < b, do: 1, else: 0
    next_program = %Intcode{
      program
      | memory: Map.put(program.memory, target, value),
        execution_pointer: program.execution_pointer + 4
    }

    {next_program, nil, :cont}
  end

  defp process_equals(%{:opcode => 8} = instruction, %__MODULE__{} = program) do
    a = get_value(program, program.execution_pointer + 1, instruction.first_mode)
    b = get_value(program, program.execution_pointer + 2, instruction.second_mode)
    target = get_address(program, program.execution_pointer + 3, instruction.third_mode)

    value = if a == b, do: 1, else: 0
    next_program = %Intcode{
      program
      | memory: Map.put(program.memory, target, value),
        execution_pointer: program.execution_pointer + 4
    }

    {next_program, nil, :cont}
  end

  defp process_move_stack_pointer(%{:opcode => 9} = instruction, %__MODULE__{} = program) do
    value = get_value(program, program.execution_pointer + 1, instruction.first_mode)

    next_program = %Intcode{
      program
      | execution_pointer: program.execution_pointer + 2,
        stack_pointer: program.stack_pointer + value
    }

    {next_program, nil, :cont}
  end

  defp process_halt(%{:opcode => 99}, %__MODULE__{} = program) do
    {program, nil, :halt}
  end


  defp get_value(%__MODULE__{} = program, pointer, 1), do: Map.get(program.memory, pointer)
  defp get_value(%__MODULE__{} = program, pointer, mode) do
    Map.get(program.memory, get_address(program, pointer, mode), 0)
  end

  defp get_address(%__MODULE__{} = program, pointer, 0), do: Map.get(program.memory, pointer, 0)

  defp get_address(%__MODULE__{} = program, pointer, 2),
    do: Map.get(program.memory, pointer, 0) + program.stack_pointer

    defp next_instruction(%Intcode{} = program) do
    parse_instruction(Map.get(program.memory, program.execution_pointer, 0))
  end

  defp parse_instruction(instruction) do
    [_, a, b, c | de] = Integer.digits(instruction + 100_000)

    %{
      :opcode => Integer.undigits(de),
      :first_mode => c,
      :second_mode => b,
      :third_mode => a
    }
  end
end
