---
layout: default
title: Documentation
---

## Documentation
<ul>
{% assign sitepages = site.pages | sort: 'order' %}
{% for page in sitepages %}
    {% if page.type == 'documentation' %}
    <li><a href="{{ site.baseurl }}{{ page.url }}"><strong>{{ page.title }}</strong></a></li>
    {% endif %}
{% endfor %}
</ul>