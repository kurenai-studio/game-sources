"""Build the two offline manuals from the in-game help content."""
import argparse
import json
from html import escape
from pathlib import Path

DOCS = Path(__file__).resolve().parents[1] / "docs"
STYLE = """
body { font: 1.05rem/1.6 system-ui, sans-serif; color: #231c16; background: #fffdf8; margin: 0; }
header, nav, main { max-width: 76ch; margin: auto; padding: 1rem; }
header { border-bottom: 0.15rem solid #8a2233; }
h1, h2, h3 { line-height: 1.2; }
a { color: #782030; }
a:focus-visible, summary:focus-visible { outline: 0.15rem solid currentColor; outline-offset: 0.2rem; }
nav ul, .setting-links { padding-inline-start: 1.4rem; }
section { margin-block-end: 2rem; }
article { margin-block-end: 1.5rem; }
.planned { font-size: 0.9em; font-weight: 600; }
@media print { body { background: white; color: black; } .skip, nav { display: none; } }
"""

def link(topic):
    return f'<li><a href="#{escape(topic["id"])}">{escape(topic["title"])}</a></li>'

def content(topic):
    tag = "h4" if "category" in topic else "h2"
    element = "article" if "category" in topic else "section"
    planned = ' <span class="planned">(Planned)</span>' if topic.get("planned") else ""
    text = "\n".join(f"<p>{escape(paragraph)}</p>" for paragraph in topic["paragraphs"])
    return (
        f'<{element} id="{escape(topic["id"])}">\n'
        f'<{tag}>{escape(topic["title"])}{planned}</{tag}>\n'
        f'{text}\n</{element}>'
    )

def manual(topics, quick=False):
    title = "Quick start" if quick else "User manual"
    sections = [topic for topic in topics if topic["quick"] or (not quick and "category" not in topic)]
    toc = "\n".join(link(topic) for topic in sections)
    body = "\n".join(content(topic) for topic in sections)
    if quick:
        body += '\n<p>See the <a href="USER_MANUAL.html">full user manual</a> for all settings.</p>'
    else:
        groups = {}
        for topic in topics:
            if "category" in topic:
                groups.setdefault(topic["category"], []).append(topic)
        toc += '\n<li><a href="#settings-reference">Settings reference</a></li>'
        body += '\n<section id="settings-reference"><h2>Settings reference</h2>'
        for category, entries in groups.items():
            body += f'\n<section><h3>{escape(category)}</h3>\n'
            body += '<ul class="setting-links">' + "\n".join(link(topic) for topic in entries) + '</ul>\n'
            body += "\n".join(content(topic) for topic in entries) + '\n</section>'
        body += '\n</section>'
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Horse Racing | {title}</title>
<style>{STYLE}</style>
</head>
<body>
<header>
<a class="skip" href="#main">Skip to main content</a>
<h1>Horse Racing | {title}</h1>
<p>SD mode</p>
</header>
<nav aria-label="Contents">
<h2>Contents</h2>
<ul>
{toc}
</ul>
</nav>
<main id="main">
{body}
</main>
</body>
</html>
"""

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Fail if the manuals need rebuilding.")
    args = parser.parse_args()
    topics = json.loads((DOCS / "help_topics.json").read_text(encoding="utf-8"))
    for name, quick in (("QUICK_START.html", True), ("USER_MANUAL.html", False)):
        path = DOCS / name
        document = manual(topics, quick)
        if args.check:
            if not path.exists() or path.read_text(encoding="utf-8") != document:
                parser.exit(1, f"{name} needs rebuilding.\n")
        else:
            path.write_text(document, encoding="utf-8", newline="\n")

if __name__ == "__main__":
    main()
