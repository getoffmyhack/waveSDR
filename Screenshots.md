---
layout: default
Title: Screenshots
---

## Screenshots

Here are some various screenshots, most can be clicked for a full size image.



{% for screenshot in site.data.screenshots %}
<figure class="screenshot">
    <a href="{{ site.baseurl }}{{ site.screenshotpath }}/{{ screenshot.name }}-full.png">
        <img src="{{ site.baseurl }}{{ site.screenshotpath }}/{{ screenshot.name }}-{{ screenshot.image }}.png" alt="{{ screenshot.description }}" />
        <figcaption>{{ screenshot.description }}</figcaption>
    </a>
</figure>
{% endfor %}