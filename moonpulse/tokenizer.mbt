/// Tokenization primitives used by the quality checks and editor integrations.

pub enum TokenKind {
  Word
  Number
  Url
  Code
  Punctuation
  Unknown
}

pub struct Token {
  value : String
  kind : TokenKind
  position : Int
  line : Int
}

pub fn kind_name(kind : TokenKind) -> String {
  match kind {
    Word => "word"
    Number => "number"
    Url => "url"
    Code => "code"
    Punctuation => "punctuation"
    Unknown => "unknown"
  }
}

fn is_number(value : String) -> Bool {
  if value == "" { return false }
  for c in value.iter() {
    if c < '0' || c > '9' { return false }
  }
  true
}

fn classify(value : String) -> TokenKind {
  if value.has_prefix("http://") || value.has_prefix("https://") { Url }
  else if value.has_prefix("`") || value.has_suffix("`") { Code }
  else if is_number(value) { Number }
  else if value == "!" || value == "?" || value == "." || value == "," || value == ":" { Punctuation }
  else if value.trim() != "" { Word }
  else { Unknown }
}

fn push_token(tokens : Array[Token], raw : String, position : Int, line : Int) -> Unit {
  let value = raw.trim().to_owned()
  if value != "" {
    tokens.push(Token::{ value, kind: classify(value), position, line })
  }
}

pub fn tokenize(input : String) -> Array[Token] {
  let tokens = []
  let mut position = 0
  let mut line_number = 1
  for line in input.split("\n") {
    for raw in line.to_owned().split(" ") {
      push_token(tokens, raw.to_owned(), position, line_number)
      position += 1
    }
    line_number += 1
  }
  tokens
}

pub fn count_kind(tokens : Array[Token], expected : TokenKind) -> Int {
  let mut result = 0
  for token in tokens {
    if kind_name(token.kind) == kind_name(expected) { result += 1 }
  }
  result
}

pub fn count_words(tokens : Array[Token]) -> Int {
  count_kind(tokens, TokenKind::Word)
}

pub fn count_numbers(tokens : Array[Token]) -> Int {
  count_kind(tokens, TokenKind::Number)
}

pub fn count_urls(tokens : Array[Token]) -> Int {
  count_kind(tokens, TokenKind::Url)
}

pub fn words_only(tokens : Array[Token]) -> Array[String] {
  let result = []
  for token in tokens {
    if token.kind is Word { result.push(token.value) }
  }
  result
}

pub fn numbers_only(tokens : Array[Token]) -> Array[String] {
  let result = []
  for token in tokens {
    if token.kind is Number { result.push(token.value) }
  }
  result
}

pub fn urls_only(tokens : Array[Token]) -> Array[String] {
  let result = []
  for token in tokens {
    if token.kind is Url { result.push(token.value) }
  }
  result
}

pub fn token_lines(tokens : Array[Token]) -> Map[Int, Int] {
  let result = Map([])
  for token in tokens { result[token.line] = result.get(token.line).unwrap_or(0) + 1 }
  result
}

pub fn token_position_checksum(tokens : Array[Token]) -> Int {
  let mut result = 0
  for token in tokens { result += token.position + token.line }
  result
}

pub fn token_summary(tokens : Array[Token]) -> String {
  "tokens=" + tokens.length().to_string() +
  ", words=" + count_words(tokens).to_string() +
  ", numbers=" + count_numbers(tokens).to_string() +
  ", urls=" + count_urls(tokens).to_string() +
  ", code=" + count_kind(tokens, TokenKind::Code).to_string()
}

pub fn token_json(tokens : Array[Token]) -> String {
  let mut result = "["
  for i = 0; i < tokens.length(); i = i + 1 {
    if i > 0 { result += "," }
    let token = tokens[i]
    result += "{\"value\":\"" + token.value.replace(old="\"", new="\\\"") +
      "\",\"kind\":\"" + kind_name(token.kind) + "\",\"position\":" +
      token.position.to_string() + ",\"line\":" + token.line.to_string() + "}"
  }
  result + "]"
}
