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

== #context { if text.lang == "da" [Om mig] else [Professional Summary] }
#block[#lang-get(data.basics, "ATSsummary")]
/ #context { if text.lang == "da" [Vanlige stakke] else [Common stacks] }: #with-fullstop(data.basics.ATScommonstacks.join(", "))


== #context { if text.lang == "da" [Kompetencer] else [Skills] }
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


== #context { if text.lang == "da" [Joberfaring] else [Work Experience] }

#for entry in data.work {
  if entry.at("ATSskip", default: false) { continue }

  work-from-entry(entry)
  linebreak()
}


== #context { if text.lang == "da" [Open Source projekter] else [Open Source Projects] }

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


== #context { if text.lang == "da" [Uddannelse] else [Education] }

#for entry in data.education [
  #if not "institution" in entry { continue }

  #edu(
    degree: { context {
      let joiner = if text.lang == "da" {"i"} else {"in"}
      if "area" in entry {
        [#lang-get(entry, "studyType") #joiner #lang-get(entry, "area")]
      } else {
        [#lang-get(entry, "studyType")]
      }
    } },
    institution: lang-get(entry, "institution"),
    location: lang-get(entry, "location", default: ""),
    dates: [#entry.date],
  )
  // #list(..entry.courses)
]
