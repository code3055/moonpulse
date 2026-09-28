/// Quality gates and export helpers for MoonPulse reports.
/// These functions are intentionally pure so they can be reused by CI tools.

pub fn quality_score(report : Report) -> Int {
  let mut score = 100
  if report.words == 0 { score -= 50 }
  if report.headings == 0 && report.lines > 8 { score -= 15 }
  if report.lexical_diversity < 0.25 && report.words > 10 { score -= 15 }
  if report.average_words_per_sentence > 35.0 { score -= 15 }
  if report.paragraphs == 1 && report.words > 80 { score -= 10 }
  if score < 0 { 0 } else { score }
}

pub fn quality_grade(score : Int) -> String {
  if score >= 90 { "excellent" }
  else if score >= 75 { "good" }
  else if score >= 60 { "needs-review" }
  else { "poor" }
}

pub fn complexity_band(report : Report) -> String {
  if report.words < 100 { "short" }
  else if report.words < 500 { "medium" }
  else if report.words < 1500 { "long" }
  else { "very-long" }
}

pub fn warning_count(report : Report) -> Int {
  report.warnings.length()
}

pub fn has_warnings(report : Report) -> Bool {
  report.warnings.length() > 0
}

pub fn keyword_count(report : Report) -> Int {
  report.keywords.length()
}

pub fn unique_word_count(report : Report) -> Int {
  report.top_words.length()
}

pub fn density(report : Report) -> Double {
  if report.lines == 0 { 0.0 } else { report.words.to_double() / report.lines.to_double() }
}

pub fn punctuation_ratio(input : String) -> Double {
  let mut punctuation = 0
  let mut total = 0
  for c in input.iter() {
    total += 1
    if c == '.' || c == ',' || c == '!' || c == '?' || c == ';' || c == ':' { punctuation += 1 }
  }
  if total == 0 { 0.0 } else { punctuation.to_double() / total.to_double() }
}

pub fn reading_hint(report : Report) -> String {
  if report.words == 0 { "请先输入一段文本" }
  else if report.average_words_per_sentence > 35.0 { "句子偏长，建议拆分" }
  else if report.headings == 0 && report.paragraphs > 3 { "建议添加标题" }
  else if report.lexical_diversity < 0.25 { "词语重复较多，建议丰富表达" }
  else { "结构和长度适合继续编辑" }
}

pub fn validate_report(report : Report) -> Array[String] {
  let errors = []
  if report.lines < 0 { errors.push("行数不能为负数") }
  if report.words < 0 { errors.push("词数不能为负数") }
  if report.characters < 0 { errors.push("字符数不能为负数") }
  if report.non_empty_lines > report.lines { errors.push("非空行数超过总行数") }
  if report.paragraphs > report.non_empty_lines && report.non_empty_lines > 0 {
    errors.push("段落数超过非空行数")
  }
  if report.sentences == 0 && report.words > 0 { errors.push("有词语但没有句子") }
  errors
}

pub fn report_status(report : Report) -> String {
  let errors = validate_report(report)
  if errors.length() > 0 { "invalid" }
  else if quality_score(report) >= 75 { "ready" }
  else { "review" }
}

pub fn report_summary(report : Report) -> String {
  "MoonPulse 分析：" + report.words.to_string() + " 词，" +
  report.lines.to_string() + " 行，" + report.paragraphs.to_string() +
  " 个段落，质量等级 " + quality_grade(quality_score(report))
}

pub fn report_markdown(report : Report) -> String {
  let mut result = "# MoonPulse 报告\n\n"
  result += "| 指标 | 数值 |\n| --- | ---: |\n"
  result += "| 行数 | " + report.lines.to_string() + " |\n"
  result += "| 非空行 | " + report.non_empty_lines.to_string() + " |\n"
  result += "| 词数 | " + report.words.to_string() + " |\n"
  result += "| 字符数 | " + report.characters.to_string() + " |\n"
  result += "| 段落 | " + report.paragraphs.to_string() + " |\n"
  result += "| 标题 | " + report.headings.to_string() + " |\n"
  result += "| 句子 | " + report.sentences.to_string() + " |\n"
  result += "| 质量分数 | " + quality_score(report).to_string() + " |\n\n"
  result += "## 建议\n\n- " + reading_hint(report) + "\n"
  result
}

pub fn report_csv(report : Report) -> String {
  "metric,value\nlines," + report.lines.to_string() + "\nnon_empty_lines," +
  report.non_empty_lines.to_string() + "\nwords," + report.words.to_string() +
  "\ncharacters," + report.characters.to_string() + "\nparagraphs," +
  report.paragraphs.to_string() + "\nheadings," + report.headings.to_string() +
  "\nsentences," + report.sentences.to_string() + "\nquality_score," +
  quality_score(report).to_string() + "\n"
}

pub fn issue_codes(report : Report) -> Array[String] {
  let codes = []
  if report.words == 0 { codes.push("EMPTY") }
  if report.headings == 0 && report.lines > 8 { codes.push("NO_HEADINGS") }
  if report.average_words_per_sentence > 35.0 { codes.push("LONG_SENTENCE") }
  if report.lexical_diversity < 0.25 && report.words > 10 { codes.push("REPETITION") }
  if report.paragraphs == 1 && report.words > 80 { codes.push("ONE_BLOCK") }
  codes
}

pub fn issue_code_text(report : Report) -> String {
  let codes = issue_codes(report)
  if codes.length() == 0 { "OK" }
  else {
    let mut result = ""
    for i = 0; i < codes.length(); i = i + 1 {
      if i > 0 { result += "," }
      result += codes[i]
    }
    result
  }
}

pub fn score_for_length(words : Int) -> Int {
  if words == 0 { 0 }
  else if words < 20 { 50 }
  else if words < 100 { 75 }
  else { 100 }
}

pub fn score_for_structure(report : Report) -> Int {
  let mut score = 40
  if report.headings > 0 { score += 20 }
  if report.paragraphs > 1 { score += 20 }
  if report.sentences > 1 { score += 20 }
  score
}

pub fn score_for_variety(report : Report) -> Int {
  if report.words == 0 { 0 }
  else if report.lexical_diversity >= 0.6 { 100 }
  else if report.lexical_diversity >= 0.4 { 80 }
  else if report.lexical_diversity >= 0.25 { 60 }
  else { 35 }
}

pub fn score_breakdown(report : Report) -> Array[(String, Int)] {
  [("length", score_for_length(report.words)),
   ("structure", score_for_structure(report)),
   ("variety", score_for_variety(report))]
}
