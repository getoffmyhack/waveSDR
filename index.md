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

>Welcome to **waveSDR**, a macOS native desktop RTLSDR software defined radio application, written in Swift.  This is a work-in-progress and as it stands, is in a very early stage.  Although the first release appears to be quite stable, there may be plenty of unseen problems.  Also note, I am designing and writing this application as a means to better learn several different programming concepts.  With that said, there are many areas with "conflicting" code where I solve the same problem by experimenting with different methods and concepts and many areas where the overall design is still in experimental stage.  Please view the technical documentation for an overview of code design and concepts.

>This site is also in it's earliest stages and will be updated (or completely changed) as I continue to work on both the application and this project site.

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
