/// Aggregate metrics for batch analysis.
pub struct BatchReport {
  files : Int
  words : Int
  characters : Int
  warnings : Int
  average_quality : Int
  failed_files : Array[String]
}

pub fn empty_batch() -> BatchReport {
  BatchReport::{ files: 0, words: 0, characters: 0, warnings: 0, average_quality: 0, failed_files: [] }
}

pub fn add_report(batch : BatchReport, path : String, report : Report) -> BatchReport {
  let failures = batch.failed_files
  if report.words == 0 { failures.push(path) }
  let quality = quality_score(report)
  let next_average = if batch.files == 0 { quality } else { (batch.average_quality * batch.files + quality) / (batch.files + 1) }
  BatchReport::{ files: batch.files + 1, words: batch.words + report.words, characters: batch.characters + report.characters, warnings: batch.warnings + report.warnings.length(), average_quality: next_average, failed_files: failures }
}

pub fn batch_json(batch : BatchReport) -> String {
  let mut files = "["
  for i = 0; i < batch.failed_files.length(); i = i + 1 {
    if i > 0 { files += "," }
    files += "\"" + batch.failed_files[i].replace(old="\"", new="\\\"") + "\""
  }
  files += "]"
  "{\"files\":" + batch.files.to_string() + ",\"words\":" + batch.words.to_string() +",\"characters\":" + batch.characters.to_string() + ",\"warnings\":" + batch.warnings.to_string() + ",\"average_quality\":" + batch.average_quality.to_string() + ",\"failed_files\":" + files + "}"
}

pub fn batch_csv(batch : BatchReport) -> String {
  "metric,value\nfiles," + batch.files.to_string() + "\nwords," + batch.words.to_string() + "\ncharacters," + batch.characters.to_string() + "\nwarnings," + batch.warnings.to_string() + "\naverage_quality," + batch.average_quality.to_string() + "\n"
}

pub fn batch_summary(batch : BatchReport) -> String {
  "files=" + batch.files.to_string() + ", words=" + batch.words.to_string() + ", characters=" + batch.characters.to_string() + ", warnings=" + batch.warnings.to_string() + ", average_quality=" + batch.average_quality.to_string()
}
