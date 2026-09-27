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
