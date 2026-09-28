test "analyze counts words and lines" {
  let report = @moonpulse.analyze("MoonBit tools\nmake work")
  inspect(report.non_empty_lines, content="2")
  inspect(report.words, content="4")
  inspect(report.non_empty_lines, content="2")
}

test "analyze handles blank input" {
  let report = @moonpulse.analyze("")
  inspect(report.words, content="0")
  inspect(report.non_empty_lines, content="0")
}

test "analyze normalizes whitespace case and punctuation" {
  let report = @moonpulse.analyze("MoonBit, MOONBIT\t tools!")
  inspect(report.words, content="3")
  inspect(report.top_words[0].0, content="moonbit")
  inspect(report.top_words[0].1, content="2")
}

test "report_json contains stable fields" {
  let json = @moonpulse.report_json(@moonpulse.analyze("MoonBit MoonBit tools"))
  inspect(json.contains("\"paragraphs\":1"), content="true")
  inspect(json.contains("\"keywords\":[{"), content="true")
}

test "quality metrics identify document structure" {
  let input = "# Title\n\nMoonBit makes tools.\nTools help teams."
  let report = @moonpulse.analyze(input)
  inspect(report.headings, content="1")
  inspect(report.paragraphs, content="2")
  inspect(report.sentences, content="2")
  inspect(@moonpulse.quality_score(report) >= 0, content="true")
  inspect(@moonpulse.validate_report(report).length(), content="1")
}

test "keywords remove common stop words" {
  let report = @moonpulse.analyze("the MoonBit tool and the MoonBit library")
  inspect(report.keywords[0].0, content="moonbit")
  inspect(report.keywords[0].1, content="2")
  inspect(@moonpulse.keyword_count(report) >= 2, content="true")
}

test "quality exports markdown and csv" {
  let report = @moonpulse.analyze("A small document.")
  let markdown = @moonpulse.report_markdown(report)
  let csv = @moonpulse.report_csv(report)
  inspect(markdown.has_prefix("# MoonPulse"), content="true")
  inspect(csv.has_prefix("metric,value"), content="true")
  inspect(@moonpulse.validate_report(report).length(), content="1")
}

test "tokenizer classifies useful token kinds" {
  let tokens = @moonpulse.tokenize("MoonBit 2026 https://moonbitlang.com")
  inspect(@moonpulse.count_words(tokens), content="1")
  inspect(@moonpulse.count_numbers(tokens), content="1")
  inspect(@moonpulse.count_urls(tokens), content="1")
  inspect(@moonpulse.token_summary(tokens).has_prefix("tokens="), content="true")
}

test "outline extracts markdown sections" {
  let sections = @moonpulse.extract_sections("# Intro\nhello\n## Usage\nrun it")
  inspect(@moonpulse.section_count(sections), content="2")
  inspect(@moonpulse.deepest_section(sections), content="2")
  inspect(@moonpulse.longest_section(sections), content="# Usage")
  inspect(@moonpulse.outline_markdown(sections).has_prefix("- Intro"), content="true")
}


