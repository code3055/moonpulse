fn main {
  let input = match @env.get_env_var("MOONPULSE_INPUT") {
    Some(text) => text
    None => "# MoonBit report\n\nMoonBit makes tools. Tools help teams."
  }
  let report = @analytics.analyze(input)
  match @env.get_env_var("MOONPULSE_FORMAT") {
    Some(format) if format == "json" => println(@analytics.report_json(report))
    Some(format) if format == "markdown" => println(@analytics.report_markdown(report))
    _ => {
      println("MoonPulse text report")
      println("lines: " + report.lines.to_string())
      println("words: " + report.words.to_string())
      println("characters: " + report.characters.to_string())
      println("paragraphs: " + report.paragraphs.to_string())
      println("headings: " + report.headings.to_string())
      println("sentences: " + report.sentences.to_string())
      println("quality: " + @analytics.quality_score(report).to_string() + " (" + @analytics.quality_grade(@analytics.quality_score(report)) + ")")
      println("keywords: " + report.keywords.length().to_string())
      println("hint: " + @analytics.reading_hint(report))
    }
  }
}
