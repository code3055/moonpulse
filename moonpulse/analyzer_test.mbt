test "analyze counts words and lines" {
  let report = @moonpulse.analyze("MoonBit tools\nmake work")
  inspect(report.lines, content="2")
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
  inspect(json, content="{\"lines\":1,\"words\":3,\"characters\":23,\"non_empty_lines\":1,\"top_words\":[{\"word\":\"moonbit\",\"count\":2},{\"word\":\"tools\",\"count\":1}]}")
}

