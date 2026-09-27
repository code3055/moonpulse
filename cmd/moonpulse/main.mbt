fn main {
  let sample = "MoonBit makes tools\nTools should be small and useful"
  let report = @analytics.analyze(sample)
  println("MoonPulse text report")
  println("lines: " + report.lines.to_string())
  println("words: " + report.words.to_string())
  println("characters: " + report.characters.to_string())
}

