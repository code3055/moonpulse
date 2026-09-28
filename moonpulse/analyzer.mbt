/// MoonPulse analysis domain model and reusable metrics.
///
/// The module deliberately keeps the input contract as `String`, so callers
/// can use the same engine with a file, editor buffer, HTTP body, or stdin.
pub struct Report {
  lines : Int
  words : Int
  characters : Int
  non_empty_lines : Int
  paragraphs : Int
  headings : Int
  sentences : Int
  average_words_per_sentence : Double
  lexical_diversity : Double
  top_words : Array[(String, Int)]
  keywords : Array[(String, Int)]
  warnings : Array[String]
}

fn normalize(word : String) -> String {
  String::from_iter(word.iter().map(c => c.to_ascii_lowercase()))
}

fn clean(input : String) -> String {
  input
    .replace(old=",", new=" ")
    .replace(old=".", new=" ").replace(old=".", new=" ").replace(old=".", new=" ")
    .replace(old="!", new=" ").replace(old="!", new=" ").replace(old="!", new=" ")
    .replace(old="?", new=" ").replace(old="?", new=" ").replace(old="?", new=" ")
    .replace(old=";", new=" ")
    .replace(old=":", new=" ")
    .replace(old="(", new=" ")
    .replace(old=")", new=" ")
    .replace(old="[", new=" ")
    .replace(old="]", new=" ")
    .replace(old="{", new=" ")
    .replace(old="}", new=" ")
    .replace(old="`", new=" ")
    .replace(old="*", new=" ")
    .replace(old="_", new=" ")
    .replace(old="/", new=" ")
    .replace(old="\\", new=" ")
    .replace(old="#", new=" ")
}

fn is_stop_word(word : String) -> Bool {
  word == "the" || word == "a" || word == "an" || word == "and" ||
  word == "or" || word == "to" || word == "of" || word == "in" ||
  word == "on" || word == "for" || word == "with" || word == "is" ||
  word == "are" || word == "this" || word == "that" || word == "it" ||
  word == "as" || word == "by" || word == "be" || word == "from"
}

fn add_word(counts : Map[String, Int], word : String) -> Unit {
  let key = normalize(word.trim().to_owned())
  if key != "" { counts[key] = counts.get(key).unwrap_or(0) + 1 }
}

fn rank_counts(counts : Map[String, Int]) -> Array[(String, Int)] {
  let ranked = []
  for (word, count) in counts { ranked.push((word, count)) }
  ranked.sort_by(fn(a, b) {
    let by_count = b.1 - a.1
    if by_count == 0 { a.0.compare(b.0) } else { by_count }
  })
  ranked
}

fn count_sentences(input : String) -> Int {
  let mut result = 0
  for c in input.iter() {
    if c == '.' || c == '!' || c == '?' { result += 1 }
  }
  if result == 0 && input.trim() != "" { 1 } else { result }
}

fn count_paragraphs(input : String) -> Int {
  let mut result = 0
  let mut in_paragraph = false
  for line in input.split("\n") {
    if line.trim() == "" {
      in_paragraph = false
    } else if !in_paragraph {
      result += 1
      in_paragraph = true
    }
  }
  result
}

fn count_headings(input : String) -> Int {
  let mut result = 0
  for line in input.split("\n") {
    let text = line.trim().to_owned()
    if text.has_prefix("#") { result += 1 }
  }
  result
}

fn build_keywords(counts : Map[String, Int]) -> Array[(String, Int)] {
  let filtered = Map([])
  for (word, count) in counts {
    if !is_stop_word(word) && word.length() > 2 { filtered[word] = count }
  }
  rank_counts(filtered)
}

fn build_warnings(
  input : String,
  words : Int,
  sentences : Int,
  headings : Int,
) -> Array[String] {
  let warnings = []
  if input.trim() == "" { warnings.push("文本为空，无法评估内容质量") }
  if words > 0 && words < 20 { warnings.push("文本较短，建议补充背景、目标和结论") }
  if sentences > 0 && words / sentences > 35 {
    warnings.push("平均句子长度偏长，建议拆分复杂句子")
  }
  if headings == 0 && input.split("\n").collect().length() > 8 {
    warnings.push("长文本没有标题，建议增加结构化小节")
  }
  warnings
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
  let top_words = rank_counts(counts)
  let sentences = count_sentences(input)
  let headings = count_headings(input)
  let paragraphs = count_paragraphs(input)
  let unique = counts.keys().length()
  let average = if sentences == 0 { 0.0 } else { words.to_double() / sentences.to_double() }
  let diversity = if words == 0 { 0.0 } else { unique.to_double() / words.to_double() }
  Report::{
    lines: input.split("\n").collect().length(), words, characters: input.length(), non_empty_lines: non_empty,
    paragraphs, headings, sentences, average_words_per_sentence: average,
    lexical_diversity: diversity, top_words, keywords: build_keywords(counts),
    warnings: build_warnings(input, words, sentences, headings),
  }
}

pub fn report_json(report : Report) -> String {
  let mut top = "["
  for i = 0; i < report.top_words.length(); i = i + 1 {
    if i > 0 { top += "," }
    let item = report.top_words[i]
    top += "{\"word\":\"" + item.0.replace(old="\"", new="\\\"") + "\",\"count\":" + item.1.to_string() + "}"
  }
  top += "]"
  let mut keywords = "["
  for i = 0; i < report.keywords.length(); i = i + 1 {
    if i > 0 { keywords += "," }
    let item = report.keywords[i]
    keywords += "{\"word\":\"" + item.0 + "\",\"count\":" + item.1.to_string() + "}"
  }
  keywords += "]"
  "{\"lines\":" + report.lines.to_string() + ",\"words\":" + report.words.to_string() +
  ",\"characters\":" + report.characters.to_string() + ",\"non_empty_lines\":" +
  report.non_empty_lines.to_string() + ",\"paragraphs\":" + report.paragraphs.to_string() +
  ",\"headings\":" + report.headings.to_string() + ",\"sentences\":" +
  report.sentences.to_string() + ",\"average_words_per_sentence\":" +
  report.average_words_per_sentence.to_string() + ",\"lexical_diversity\":" +
  report.lexical_diversity.to_string() + ",\"top_words\":" + top + ",\"keywords\":" + keywords + "}"
}








