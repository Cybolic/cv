#let isodate-to-datetime(date-string) = {
  datetime(
    year: int(date-string.split("-").at(0)),
    month: int(date-string.split("-").at(1)),
    day: int(date-string.split("-").at(2)),
  )
}

#let ends-in-period(body) = {
  if type(body) == str {
    body.trim().ends-with(".")
  } else if type(body) == content and body.has("text") {
    ends-in-period(body.text)
  } else if type(body) == array {
    if body.len() == 0 {
      false
    } else {
      ends-in-period(body.last())
    }
  } else {
    false
  }
}
// Ensure a full-stop at the end of the content
#let with-fullstop(body) = {
  let ends-in-fullstop = ends-in-period(body)
  [#body#{if not ends-in-fullstop [.]}]
}
