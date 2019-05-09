defmodule ParserTest do
  use ExUnit.Case
  import Parser

  test "with parentheses" do
    code = "func(1, 2)"
    ast = parse(code)
    {_, meta, _} = ast

    assert Macro.to_string(ast) == code
    assert meta == [line: 1, column: 1, end_line: 1, end_column: 10]
  end

  test "with inner parentheses" do
    code = "func((a + b) * c, 2)"
    ast = parse(code)
    {_, meta, _} = ast

    assert Macro.to_string(ast) == code
    assert meta == [line: 1, column: 1, end_line: 1, end_column: 20]
  end

  test "with inner functions" do
    code = "func1(func2(1), 2)"
    ast = parse(code)
    {_, meta, _} = ast

    assert Macro.to_string(ast) == code
    assert meta == [line: 1, column: 1, end_line: 1, end_column: 18]
  end

  test "with parentheses and multiple lines" do
    code = """
    func(
      (a + b) * c,
    2)
    """
    ast = parse(code)
    {_, meta, _} = ast

    assert Macro.to_string(ast) == "func((a + b) * c, 2)"
    assert meta == [line: 1, column: 1, end_line: 3, end_column: 2]
  end

  test "remote call" do
    code = "Remote1.Remote2.func(1, 2)"
    ast = parse(code)
    {_, meta, _} = ast

    assert Macro.to_string(ast) == code
    assert meta == [line: 1, column: 16, end_line: 1, end_column: 26]
  end

  test "remote call with multiple lines" do
    code = """
    Remote1.
      Remote2.
        func(
          1,
    2)
    """
    ast = parse(code)
    {_, meta, _} = ast

    assert Macro.to_string(ast) == "Remote1.Remote2.func(1, 2)"
    assert meta == [line: 2, column: 10, end_line: 5, end_column: 2]
  end
end
