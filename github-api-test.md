---
layout: default
---

# Github API

| Key        | Value    |
|:-----------|:---------|{% for release in site.github.releases[0].assets %}{% for hash in release %}
| {{ hash[0] }} | {{ hash[1] }} |{% endfor %}{% endfor %}