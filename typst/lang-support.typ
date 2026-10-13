#let lang-get-in-context(obj, key, default: none) = {
  let lang = text.lang
  if lang != "en" {
    obj.at(key + "." + lang, default: obj.at(key, default: default))
  } else {
    obj.at(key, default: default)
  }
}
#let lang-get(obj, key, default: none) = context {
  lang-get-in-context(obj, key, default: default)
}

#let lang-pick(default, options) = context {
  let lang = text.lang
  if lang == "en" {
    default
  } else {
    options.at(lang, default: default)
  }
}

#let lang-date-display(date, format) = context {
  let lang = text.lang
  let output = date.display(format)
  if lang == "da" {
    output.replace("May", "Maj").replace("Oct", "Okt")
  } else {
    output
  }
}
