#!/bin/bash
# Builds the CV and the resume on your computer and copies the two PDFs into
# the website, so visitors download them from the site itself.
#
#   bash assets/update-cv.sh
#
# Then commit and push to publish them. If a build fails, the script stops and
# the copies already on the website stay as they are.

# Where the CV and the resume live on your computer, and what they are called
CV_DIR="$HOME/Library/CloudStorage/Dropbox/Public/CV"
RESUME_DIR="$HOME/Library/CloudStorage/Dropbox/Public/Resume"
CV="CV_Himel_Mallick"
RESUME="Resume_Himel_Mallick"

set -e
SITE="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$SITE/files"

echo "Building the CV..."
(cd "$CV_DIR" && quarto render "$CV.qmd")
echo "Building the resume..."
(cd "$RESUME_DIR" && quarto render "$RESUME.qmd")

cp "$CV_DIR/$CV.pdf" "$SITE/files/$CV.pdf"
cp "$RESUME_DIR/$RESUME.pdf" "$SITE/files/$RESUME.pdf"

echo
echo "Copied $CV.pdf and $RESUME.pdf into the website (files/)."
echo "To publish them:  git add -A && git commit -m \"Update CV\" && git push"
