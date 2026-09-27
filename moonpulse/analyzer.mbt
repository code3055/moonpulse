pub struct Report {
  lines : Int
  words : Int
  characters : Int
  non_empty_lines : Int
  top_words : Array[(String, Int)]
}

fn normalize(word : String) -> String {
  String::from_iter(word.iter().map(c => c.to_ascii_lowercase()))
}

fn clean(input : String) -> String {
  input
    .replace(old=",", new=" ")
    .replace(old=".", new=" ")
    .replace(old="!", new=" ")
    .replace(old="?", new=" ")
    .replace(old=";", new=" ")
    .replace(old=":", new=" ")
    .replace(old="(", new=" ")
    .replace(old=")", new=" ")
}

fn add_word(counts : Map[String, Int], word : String) -> Unit {
  let key = normalize(word.trim().to_owned())
  if key != "" { counts[key] = counts.get(key).unwrap_or(0) + 1 }
}

pub fn analyze(input : String) -> Report {
  let lines = input.split("\n")
  let mut words = 0
  let mut non_empty = 0
  let counts = Map([])
  for line in lines {
    if line.trim() != "" { non_empty += 1 }
    for token in clean(line.to_owned()).split(" ") {
      if token.trim() != "" {
        words += 1
        add_word(counts, token.to_owned())
      }
    }
  }
  let ranked = []
  for (word, count) in counts { ranked.push((word, count)) }
  ranked.sort_by(fn(a, b) {
    let by_count = b.1 - a.1
    if by_count == 0 { a.0.compare(b.0) } else { by_count }
  })
  Report::{ lines: non_empty, words, characters: input.length(), non_empty_lines: non_empty, top_words: ranked }
}


