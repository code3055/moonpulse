pub struct Config {
  format : String
  recursive : Bool
  pattern : String
  min_words : Int
  max_keywords : Int
  fail_on_warning : Bool
}

pub fn default_config() -> Config {
  Config::{ format: "text", recursive: false, pattern: "*.md", min_words: 0, max_keywords: 10, fail_on_warning: false }
}

fn parse_bool(value : String, fallback : Bool) -> Bool {
  let normalized = value.trim().to_owned()
  if normalized == "true" || normalized == "1" || normalized == "yes" { true }
  else if normalized == "false" || normalized == "0" || normalized == "no" { false }
  else { fallback }
}

fn parse_int(value : String, fallback : Int) -> Int {
  let text = value.trim().to_owned()
  if text == "" { return fallback }
  let mut result = 0
  for c in text.iter() {
    if c < '0' || c > '9' { return fallback }
    result = result * 10 + c.to_int() - '0'.to_int()
  }
  result
}

pub fn parse_config(input : String) -> Config {
  let mut format = "text"
  let mut recursive = false
  let mut pattern = "*.md"
  let mut min_words = 0
  let mut max_keywords = 10
  let mut fail_on_warning = false
  for raw_line in input.split("\n") {
    let line = raw_line.trim().to_owned()
    let fields = line.split("=").collect()
    if line != "" && !line.has_prefix("#") && fields.length() >= 2 {
      let key = fields[0].trim().to_owned()
      let value = fields[1].trim().to_owned()
      if key == "format" { format = value }
      else if key == "recursive" { recursive = parse_bool(value, recursive) }
      else if key == "pattern" { pattern = value }
      else if key == "min_words" { min_words = parse_int(value, min_words) }
      else if key == "max_keywords" { max_keywords = parse_int(value, max_keywords) }
      else if key == "fail_on_warning" { fail_on_warning = parse_bool(value, fail_on_warning) }
    }
  }
  Config::{ format, recursive, pattern, min_words, max_keywords, fail_on_warning }
}

pub fn format_name(config : Config) -> String { config.format }
pub fn recursive_enabled(config : Config) -> Bool { config.recursive }
pub fn file_pattern(config : Config) -> String { config.pattern }
pub fn minimum_words(config : Config) -> Int { config.min_words }
pub fn keyword_limit(config : Config) -> Int { config.max_keywords }
pub fn fail_on_warning(config : Config) -> Bool { config.fail_on_warning }

pub fn should_include(config : Config, words : Int) -> Bool { words >= config.min_words }

pub fn config_json(config : Config) -> String {
  "{\"format\":\"" + config.format + "\",\"recursive\":" + config.recursive.to_string() +
  ",\"pattern\":\"" + config.pattern + "\",\"min_words\":" + config.min_words.to_string() +
  ",\"max_keywords\":" + config.max_keywords.to_string() +
  ",\"fail_on_warning\":" + config.fail_on_warning.to_string() + "}"
}

pub fn config_help() -> String {
  "format=text|json|markdown|csv\nrecursive=false\npattern=*.md\nmin_words=0\nmax_keywords=10\nfail_on_warning=false"
}
