pub struct Report {
  lines : Int
  words : Int
  characters : Int
  non_empty_lines : Int
  top_words : Array[(String, Int)]
}

pub fn analyze(input : String) -> Report {
  let lines = input.split("\n")
  let mut words = 0
  let mut non_empty = 0
  for line in lines {
    if line.trim() != "" { non_empty += 1 }
    for token in line.split(" ") {
      if token.trim() != "" { words += 1 }
    }
  }
  Report::{
    lines: non_empty,
    words,
    characters: input.length(),
    non_empty_lines: non_empty,
    top_words: [],
  }
}


