# How to use

    hugo new content/post/2022-07-10_this_is_the_filename

Then edit the file, adjust the title first.

Render and preview locally with

    hugo server -D

Then open http://localhost:1313/ to preview,

When happy, set the post to `draft: false` in the meta data.

Generate the output files by just calling

    hugo

Then, publish:

    git add content/post/
    git add public/
    git commit -m "meaningful message"
    ./push-to-server.sh

This will push to freedombox into `~kopfkind/website-staging/`, you can
then publich it to box.axelknauf.de by logging in and copying to Apache:

    ssh kopfkind@box
    ./push-to-apache.sh

Then check https://box.axelknauf.de/ for the new content.

