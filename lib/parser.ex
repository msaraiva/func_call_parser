defmodule Parser do

  def parse(code, opts \\ []) do
    file = Keyword.get(opts, :file, "nofile")

    case :elixir.string_to_tokens(to_charlist(code), 1, file, []) do
      {:ok, tokens} ->
        tokens
        |> Enum.reverse()
        |> encode_tokens_metadata()
        |> :elixir.tokens_to_quoted(file, [columns: true])
        |> decode_ast_metadata()
      {:error, _error_msg} = error ->
        error
    end
  end

  defp encode_tokens_metadata(tokens) do
    {result, _, _} = Enum.reduce(tokens, {[], [], nil}, &update_token/2)
    result
  end

  defp update_token({:")", _meta} = token, {result, parens, _}) do
    {[token | result], [token | parens], nil}
  end

  defp update_token({:"(", _meta} = token, {result, [paren | parens], _}) do
    {[token | result], parens, paren}
  end

  defp update_token({:., meta}, {[{:paren_identifier, _, _} = last_token | result], parens, _}) do
    {_, {encoded_lines, encoded_cols, _}, _} = last_token
    {_line, end_line} = decode_numbers(encoded_lines)
    {_col, end_col} = decode_numbers(encoded_cols)

    {line, col, scope} = meta
    updated_meta = {encode_numbers(line, end_line), encode_numbers(col, end_col), scope}
    updated_token = {:., updated_meta}
    {[updated_token, last_token | result], parens, nil}
  end

  defp update_token({:paren_identifier, meta, name}, {result, parens, closing_paren}) do
    {line, col, scope} = meta
    {_, {paren_line, paren_col, _}} = closing_paren
    encoded_lines = encode_numbers(line, paren_line)
    encoded_cols = encode_numbers(col, paren_col)
    updated_token = {:paren_identifier, {encoded_lines, encoded_cols, scope}, name}

    {[updated_token | result], parens, nil}
  end

  defp update_token(token, {result, parens, _}) do
    {[token | result], parens, nil}
  end

  defp encode_numbers(n1, n2) do
    <<n::60>> = <<n1::30, n2::30>>
    -n
  end

  defp decode_numbers(n) do
    <<n1::30, n2::30>> = <<-n::60>>
    {n1, n2}
  end

  defp decode_ast_metadata({:ok, ast}) do
    Macro.prewalk(ast, &decode_identifier/1)
  end

  defp decode_ast_metadata(error) do
    error
  end

  def decode_identifier({name, [line: encoded_lines, column: encoded_cols], args}) when encoded_lines < 0 do
    {line, end_line} = decode_numbers(encoded_lines)
    {col, end_col} = decode_numbers(encoded_cols)
    {name, [line: line, column: col, end_line: end_line, end_column: end_col], args}
  end

  def decode_identifier(ast) do
    ast
  end
end
