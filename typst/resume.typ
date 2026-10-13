// Based in part on https://github.com/stuxf/basic-typst-resume-template
// to try and make the output more readable by ATS software (my main issue with LaTeX)

// #import "@preview/scienceicons:0.1.0": orcid-icon
#import "lang-support.typ": *
#import "utils.typ": *


#let resume(
  author: "",
  author-position: left,
  personal-info-position: left,
  pronouns: "",
  location: "",
  email: "",
  personal-site: "",
  profiles: (),
  phone: "",
  orcid: "",
  accent-color: "#000000",
  secondary-color: "#000000",
  muted-color: "#cccccc",
  faded-color: "#555555",
  font: "Lato",
  paper: "a4",
  author-font-size: 18pt,
  profiles-font-size: 9pt,
  font-size: 10pt,
  lang: "en",
  body,
) = {

  let accent-color = rgb(accent-color)
  let secondary-color = rgb(secondary-color)
  let muted-color = rgb(muted-color)
  let faded-color = rgb(faded-color)

  // Sets document metadata
  set document(author: author, title: author)

  // Document-wide formatting, including font and margins
  set text(
    // LaTeX style font
    font: font,
    size: font-size,
    lang: lang,
    //// ATS help
    // Disable ligatures so parsing is less likely to fail
    ligatures: false,
    // Limit hyphenation as it's often parsed as separate/cut words
    costs: (hyphenation: 1000%),
  )

  // Recommended margins (it should actually be 1.25cm, but we're pressed on space)
  set page(
    margin: (if paper == "a4" {1.2cm} else {0.5in}),
    paper: paper,
  )

  set terms(
    separator: ": ",
    spacing: auto,
    // hanging-indent: 2em,
    tight: true,
  )

  // Small caps for section titles
  show heading.where(level: 2): it => [
    #pad(top: -2pt, bottom: -10pt, [#smallcaps(it.body)])
    #pad(bottom: -2pt, [#line(length: 100%, stroke: 0.5pt + muted-color)])
  ]

  // Accent Color Styling
  show heading.where(level: 1).or(heading.where(level: 2)): set text(
    fill: accent-color,
  )

  // Show work headers as regular text (don't line break them)
  show heading.where(level: 3): it => [
    #it.body
  ]

  show <keyword>: set text(accent-color)

  show selector(<work-domain>): it => [
    // #pad(
    //   top: -4pt,
    //   bottom: -4pt,
    //   [#line(length: 100%, stroke: 0.5pt + accent-color)]
    // )<work-line>
    // #pad(
    //   top: -2pt,
    //   bottom: -2pt,
      #strong(
        delta: 200,
        it.body
      )
    // )
  ]

  // Link styles
  show link: it => {
    underline(
      stroke: secondary-color.lighten(50%),
      text(
        fill: secondary-color,
        it
      )
    )
  }

  // Name will be aligned left, bold and big
  show heading.where(level: 1): it => [
    #set align(author-position)
    #set text(
      weight: 700,
      size: author-font-size,
    )
    #pad(it.body)
  ]


  // Level 1 Heading
  [= #(author)]

  // Personal Info Helper
  let contact-item(value, prefix: "", link-type: "") = {
    if value != "" {
      if link-type != "" {
        // don't break links on full stop or slashes
        let text = str(prefix + value).replace(regex("\."), "\u{2060}.\u{2060}").replace(regex("/"), "\u{2060}/\u{2060}")
        link(link-type + value)[#(text)]
      } else {
        value
      }
    }
  }

  // Personal Info
  pad(
    top: 0.25em,
    align(personal-info-position)[
      #{
        set text( size: profiles-font-size, )
        let items = (
          contact-item(pronouns),
          contact-item(phone),
          contact-item(location),
          contact-item(email, link-type: "mailto:"),
          contact-item(personal-site, link-type: "https://"),
          ..(
            profiles.map((profile) => {
              let visible-url = profile.url.replace(regex("^https://"), "")
              contact-item(visible-url, link-type: "https://")
            })
          )
          // contact-item(github, link-type: "https://"),
          // contact-item(linkedin, link-type: "https://"),
          // contact-item(orcid, prefix: [#orcid-icon(color: rgb("#AECD54"))orcid.org/], link-type: "https://orcid.org/"),
        )
        items.filter(x => x != none).join(text(fill: rgb(muted-color), " \u{00A0}|\u{00A0}\u{00A0}"))
        // items.filter(x => x != none).join("  ")
      }
    ],
  )

  // Main body.
  set par(justify: true, spacing: 1.2em)

  body
}

// Generic two by two component for resume
#let generic-two-by-two(
  top-left: "",
  top-right: "",
  bottom-left: "",
  bottom-right: "",
) = {
  [
    #top-left #h(1fr) #top-right \
    #bottom-left #h(1fr) #bottom-right
  ]
}

// Generic one by two component for resume
#let generic-one-by-two(
  left: "",
  right: "",
) = {
  [
    #left #h(1fr) #right
  ]
}

// Cannot just use normal --- ligature because ligatures are disabled for good reasons
#let dates-helper(
  start-date: "",
  end-date: "",
) = {
  start-date + " " + $dash.em$ + " " + end-date
}

#let keyword-list(keywords) = {
  keywords.map((k) => [#k<keyword>]).join(", ")
}

// Section components below
#let edu(
  institution: "",
  institutionNote: "",
  dates: "",
  degree: "",
  gpa: "",
  location: "",
  // Makes dates on upper right like rest of components
  consistent: false,
) = {
  if consistent {
    // edu-constant style (dates top-right, location bottom-right)
    generic-two-by-two(
      top-left: [#strong(institution)#{if institutionNote != "" [ #institutionNote]}],
      top-right: dates,
      bottom-left: emph(degree),
      bottom-right: emph(location),
    )
  } else {
    // original edu style (location top-right, dates bottom-right)
    generic-two-by-two(
      top-left: [#strong(institution)#{if institutionNote != "" [ #institutionNote]}],
      top-right: location,
      bottom-left: emph(degree),
      bottom-right: emph(dates),
    )
  }
}

#let work(
  title: "",
  dates: "",
  company: "",
  location: "",
  domain: "",
) = {
  generic-two-by-two(
    top-left: heading(offset: 2, [*#title*<work-title>]),
    top-right: dates,
    bottom-left: company,
    bottom-right: emph(location),
  )
  [
    
    *#domain*<work-domain>
  ]
}

#let work-from-entry(entry) = {

  let startDate = lang-date-display(
    isodate-to-datetime(entry.at("ATSstartDate", default: entry.startDate)),
    "[month repr:short] [year]"
  )

  let endDate = if "endDate" in entry {
    lang-date-display(
      isodate-to-datetime(entry.endDate),
      "[month repr:short] [year]"
    )
  } else {
    context { if text.lang == "da" {
      "nu"
    } else {
      "ongoing"
    } }
  }

  work(
    // title: entry.at("ATSposition", default: entry.position),
    // company: entry.name,
    title: lang-get(entry, "ATSposition", default: lang-get(entry, "position")),
    company: lang-get(entry, "name"),
    dates: dates-helper(
      start-date: startDate,
      end-date: endDate,
    ),
    location: [
      #{if "country" in entry [#lang-get(entry, "country"), ]}#lang-get(entry, "location")
    ],
    domain: lang-get(entry, "domain"),
  )
  // list(..entry.ATShighlights.map(with-fullstop))
  context {
    let hls = lang-get-in-context(entry, "ATShighlights")
    list(..hls.map(with-fullstop))

    if text.lang == "da" [Tekn.] else [Tech]
  }
  [: #keyword-list(entry.at("ATSkeywords", default: entry.keywords))]
  linebreak()
}

#let project(
  role: "",
  name: "",
  url: "",
  dates: "",
) = {
  generic-one-by-two(
    left: {
      set heading(offset: 2)
      if role == "" {
        [ #heading(name) #if url != "" and dates != "" [ (#link("https://" + url)[#url])]]
      } else {
        [ #heading(role) #name #if url != "" and dates != "" [ (#link("https://" + url)[#url])]]
      }
    },
    right: {
      if dates == "" and url != "" {
        link("https://" + url)[#url]
      } else {
        dates
      }
    },
  )
}

#let certificates(
  name: "",
  issuer: "",
  url: "",
  date: "",
) = {
  [
    *#name*, #issuer
    #if url != "" {
      [ (#link("https://" + url)[#url])]
    }
    #h(1fr) #date
  ]
}

#let extracurriculars(
  activity: "",
  dates: "",
) = {
  generic-one-by-two(
    left: strong(activity),
    right: dates,
  )
}
