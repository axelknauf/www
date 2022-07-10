---
title: "YouTube without ads on iOS"
date: 2022-07-10T16:22:27+02:00
draft: true
---

I bought an iPad last year. Being used to browsing the web with Firefox and uBlock Origin, I was overwhelmed by the amount of advertising when using it. I found out that iOS forces browsers to use the built-in Webkit engine and does not allow extensions at all.

Here's what I did to be able to browse the web and watch YouTube videos without advertisements on iOS.

## Network-wide DNS filtering

First of all I installed a [PiHole DNS server](https://pi-hole.net/) on my network and configured my router to announce it as DNS host for all clients.

Works fine for regular clients, but iOS is different. By default, all DNS queries will be routed through iCloud (officially for privacy reasons, but I am sure they're doing some kind of tracking). So I had to change the network settings using a manually configured DNS server.

That got rid of in-app advertisements, yay! But alas, opening YouTube always confronted my with in-video ads every few minutes. I did some research and found out:

- the native YT app (produced by Google) will always show ads, regardless of what you do. The only way out is subscribing.
- using any browser (Safari, Firefox, DuckDuckGo) all use the same Webkit engine which does not block ads

Not at all? Yes, there is a way.

## Configuring the browser(s)

I installed the "Kaboom" ad blocking extension into Safari, that made web-browsing a bit better. Still, YT ads. But then I found the "Vinegar" extension (at a cost of 2 EUR) and installed it. I had to enable it in the Safari settings, and essentially it only does one thing: replace the flashy YT player with a standard HTML5 &lt;video&gt; element.

This is pretty useful:

- ad blocking now works in Safari, including YT videos
- the native HTML5 player has all standard controls, like PIP, theater mode, skipping etc.

It only works in Safari, though, because the plugins are not enabled for the derived browsers. But still.

## How to avoid the YT app

By default iOS will open YouTube links in the native app. To stay in the browser I had to long-press YT links and choose "open in tab" instead. Afterwards Safari understood that I want to browse and watch YT in the browser.

Hooray for watching video on my tablet without advertisements!

