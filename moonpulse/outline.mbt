/// Document outline extraction for Markdown-like text.

pub struct Section {
  title : String
  depth : Int
  start_line : Int
  body_lines : Int
  word_count : Int
}

fn heading_depth(line : String) -> Int {
  let text = line.trim().to_owned()
  let mut depth = 0
  for c in text.iter() {
    if c == '#' { depth += 1 } else { break }
  }
  depth
}

fn title_from_heading(line : String) -> String {
  let text = line.trim().to_owned()
  text.replace(old="#", new="").trim().to_owned()
}

fn words_in_line(line : String) -> Int {
  let mut result = 0
  for token in line.split(" ") {
    if token.trim() != "" { result += 1 }
  }
  result
}

pub fn extract_sections(input : String) -> Array[Section] {
  let sections = []
  let mut current : Section? = None
  let mut line_number = 1
  for line in input.split("\n") {
    let owned = line.to_owned()
    let depth = heading_depth(owned)
    if depth > 0 {
      match current {
        Some(section) => sections.push(section)
        None => ()
      }
      current = Some(Section::{ title: title_from_heading(owned), depth, start_line: line_number, body_lines: 0, word_count: 0 })
    } else {
      match current {
        Some(section) => {
          current = Some(Section::{ title: section.title, depth: section.depth, start_line: section.start_line, body_lines: section.body_lines + 1, word_count: section.word_count + words_in_line(owned) })
        }
        None => ()
      }
    }
    line_number += 1
  }
  match current {
    Some(section) => sections.push(section)
    None => ()
  }
  sections
}

pub fn section_count(sections : Array[Section]) -> Int {
  sections.length()
}

pub fn deepest_section(sections : Array[Section]) -> Int {
  let mut depth = 0
  for section in sections { if section.depth > depth { depth = section.depth } }
  depth
}

pub fn longest_section(sections : Array[Section]) -> String {
  let mut title = ""
  let mut words = -1
  for section in sections {
    if section.word_count > words { words = section.word_count; title = section.title }
  }
  title
}

pub fn outline_markdown(sections : Array[Section]) -> String {
  let mut result = ""
  for section in sections {
    result += String::repeat("  ", section.depth - 1) + "- " + section.title +
      " (line " + section.start_line.to_string() + ", " + section.word_count.to_string() + " words)\n"
  }
  result
}

pub fn sections_json(sections : Array[Section]) -> String {
  let mut result = "["
  for i = 0; i < sections.length(); i = i + 1 {
    if i > 0 { result += "," }
    let section = sections[i]
    result += "{\"title\":\"" + section.title + "\",\"depth\":" +
      section.depth.to_string() + ",\"start_line\":" + section.start_line.to_string() +
      ",\"body_lines\":" + section.body_lines.to_string() +
      ",\"word_count\":" + section.word_count.to_string() + "}"
  }
  result + "]"
}

