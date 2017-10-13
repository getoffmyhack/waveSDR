---
# You don't need to edit this file, it's empty on purpose.
# Edit theme's home layout instead if you wanna make some changes
# See: https://jekyllrb.com/docs/themes/#overriding-theme-defaults
layout: default
title: waveSDR
---

<!--
<iframe width="560" height="420" src="http://www.youtube.com/embed/oHg5SJYRHA0?color=white&theme=light"></iframe>
-->

![waveSDR]({{ site.baseurl }}{{ site.imagepath }}/screenshot.png)

## Releases

<ul>
{% for release in site.github.releases %}
    <li><a href="{{ release.html_url }}"><strong>{{ release.name }}</strong></a> <em>{{ release.published_at }}</em> </li>
{% endfor %}
</ul>


## Documentation
<ul>
{% assign sitepages = site.pages | sort: 'order' %}
{% for page in sitepages %}
    {% if page.type == 'documentation' %}
    <li><a href="{{ site.baseurl }}{{ page.url }}"><strong>{{ page.title }}</strong></a></li>
    {% endif %}
{% endfor %}
</ul>
