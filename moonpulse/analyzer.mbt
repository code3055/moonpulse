pub struct Report {
  lines : Int
  words : Int
  characters : Int
  non_empty_lines : Int
  top_words : Array[(String, Int)]
}

fn add_word(counts : Map[String, Int], word : String) -> Unit {
  if word.trim() != "" {
    counts[word] = counts.get(word).unwrap_or(0) + 1
  }
}

pub fn analyze(input : String) -> Report {
  let lines = input.split("\n")
  let mut words = 0
  let mut non_empty = 0
  let counts = Map([])
  for line in lines {
    if line.trim() != "" { non_empty += 1 }
    for token in line.split(" ") {
      let word = token.trim().to_owned()
      if word != "" {
        words += 1
        add_word(counts, word)
      }
    }
  }
  let ranked = []
  for (word, count) in counts { ranked.push((word, count)) }
  ranked.sort_by(fn(a, b) { b.1 - a.1 })
  Report::{
    lines: non_empty,
    words,
    characters: input.length(),
    non_empty_lines: non_empty,
    top_words: ranked,
  }
}




