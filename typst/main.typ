#import "resume.typ": *

#let yaml-file = sys.inputs.at("yaml-file", default: "/resume.yaml")
#let language = sys.inputs.at("language", default: "en")
#let data = yaml(yaml-file)
#let name = data.basics.name
// #let location = lang-get(data.basics.location, "address")
#let email = data.basics.email
#let personal-site = data.basics.url.replace(regex("^https://"), "")

#let accent-color = "#43069A"
#let secondary-color = rgb(accent-color).rotate(-45deg)

#set list(tight: false, spacing: 0.9em)
#show: resume.with(
  author: name,
  // location: location,
  email: email,
  profiles: data.basics.profiles,
  personal-site: personal-site,
  accent-color: accent-color,
  secondary-color: secondary-color,
  author-position: left,
  personal-info-position: left,
  profiles-font-size: 8.4587pt, // precisely enough to fill the width
  lang: language,
)

== #lang-pick("Professional Summary", (da: "Om mig",))
#block[#lang-get(data.basics, "ATSsummary")]
/ #lang-pick("Common stacks", (da: "Vanlige stakke",)): #with-fullstop(keyword-list(data.basics.ATScommonstacks))


== #lang-pick("Skills", (da: "Kompetencer",))
#for skill in data.skillsMain {
  let years = if "startYear" in skill {
    str(datetime.today().year() - skill.startYear)
  } else { "" }
  context {
    let keywords = skill.at("keywords")
    if text.lang != "en" {
      keywords = skill.at("keywords." + text.lang, default: skill.at("keywords"))
    }
    let description = keywords
      .join(", ")
      .replace("$$years", years)

    [/ #lang-get(skill, "name"): #with-fullstop(description)]
  }
}


== #lang-pick("Work Experience", (da: "Joberfaring",))

#for entry in data.work {
  if entry.at("ATSskip", default: false) { continue }

  work-from-entry(entry)
  linebreak()
}


== #lang-pick("Open Source Projects", (da: "Open Source projekter",))

#for entry in data.ATSprojects [
  / #{
    if "url" in entry {
      link(entry.url, [#lang-get(entry, "name")])
    } else {
      [#lang-get(entry, "name")]
    }

  }: #context{
    with-fullstop(lang-get-in-context(entry, "description"))
  }
  // #list(..entry.highlights)
]


== #lang-pick("Education", (da: "Uddannelse",))

#for entry in data.education [
  #if not "institution" in entry { continue }

  #edu(
    consistent: false,
    degree: { context {
      let joiner = lang-pick("in", (da: "i",))
      if "area" in entry {
        [#lang-get(entry, "studyType") #joiner #lang-get(entry, "area")]
      } else {
        [#lang-get(entry, "studyType")]
      }
    } },
    institution: lang-get(entry, "institution"),
    institutionNote: lang-get(entry, "institutionNote"),
    location: lang-get(entry, "location", default: ""),
    dates: [#lang-get(entry, "completionType") #entry.date],
  )
  // #list(..entry.courses)
]
