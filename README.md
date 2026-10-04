# himelmallick.github.io

Source for [himelmallick.org](https://www.himelmallick.org), the personal website of Himel Mallick, built with [Quarto](https://quarto.org).

The site is a small set of plain text files. It has a home page, a few list pages (experience, papers, software, awards) and a blog with an RSS feed. It adapts to phones, tablets and desktops, follows the visitor's light or dark setting, serves its own typeface, and publishes itself through GitHub Actions on every push.

The repository is meant as a resource for the community: you are welcome to use it as a base template for your own site. The steps below show how, by hand or with Claude.

## Use this as a starting point

You need [Quarto](https://quarto.org/docs/get-started/) and a GitHub account. RStudio or Positron is optional.

**1. Get your own copy.** Fork this repository (or download it) and name your copy `<your-username>.github.io`.

**2. Preview it.** In the project folder:

```
quarto preview
```

**3. Replace the content with yours.**

| File | What to change |
|---|---|
| `_quarto.yml` | Site title, description, `site-url`, menu, CV links, footer |
| `index.qmd` | Name, tagline, biography, research areas, education, profile links, contact |
| `assets/himel-mallick.jpg` | Your photo (600 x 900 pixels). Rename it and update the name in `index.qmd` |
| `experience/index.qmd` | Positions and skills |
| `papers/index.qmd` | Papers |
| `software/index.qmd` | Software |
| `talks/index.qmd` | Talks and short courses |
| `awards/index.qmd` | Honors and awards |
| `post/` | Delete the existing post folders. Keep `_template`, `_metadata.yml` and `index.qmd` |
| `assets/theme.scss` | Six colors at the top set the palette. `assets/theme-dark.scss` holds the dark versions |
| `assets/favicon.svg` | The browser tab icon |

Two parts of the home page are specific to this site and can be removed from `index.qmd`: the "Mallick Lab" video section, and the line `{{< include assets/_laplace.html >}}`, which draws the curve under the name.

To drop a page, delete its folder and remove it from `render` and `navbar` in `_quarto.yml`. To add one, create `<name>/index.qmd` and add it in the same two places.

**4. Publish.** In your repository on GitHub, open Settings, then Pages, and set Source to **GitHub Actions**. Push your changes. The workflow in `.github/workflows/publish.yml` builds the site and publishes it at `https://<your-username>.github.io` in about two minutes.

## Adapt it with Claude

This site was moved from Hugo to Quarto and redesigned with the help of [Claude](https://claude.com). You can make the template yours the same way. Open your copy of the project folder in Claude Code (or give Claude access to the folder) and work through prompts like the ones below, one at a time. Review each change in `quarto preview` before moving on.

**1. Replace the content.**

```
This folder is a Quarto personal website I am using as a template. My CV is
attached. Replace the content of index.qmd, experience/index.qmd,
papers/index.qmd, software/index.qmd and awards/index.qmd with my information.
Keep the layout, the styles and the file structure unchanged. Ask me about
anything my CV does not cover.
```

**2. Update the site settings.**

```
Update _quarto.yml for me: site title, description, site-url
(https://<my-username>.github.io), the menu, the CV and Resume links and the
footer. My details are: <name, affiliation, address, email, GitHub handle>.
```

**3. Swap the photo and remove what is specific to the original site.**

```
Use the attached photo as the main portrait: crop it to 600 x 900 pixels, save
it in assets/ under my name and update index.qmd. Remove the "Mallick Lab" video
section and the curve under the name. Delete the existing posts and keep
post/_template, post/_metadata.yml and post/index.qmd.
```

**4. Change the look (optional).**

```
Change the accent color to <color> in assets/theme.scss and choose a matching
dark-mode value in assets/theme-dark.scss. Check that links and headings keep
enough contrast in both modes.
```

**5. Bring your old posts along (optional).**

```
My current site is at <address> (source in <folder>). Move its blog posts into
post/, one folder per post, and keep every post at the same web address it has
today. List anything that could not be carried over.
```

**6. Check the result.**

```
Render the site and check every page at phone, tablet and desktop widths.
Report broken links, missing images, text that overflows and anything that
loads from a third-party server, then fix what you find.
```

**7. Publish.**

```
Walk me through the first push to GitHub for this site, including the GitHub
Pages setting, and tell me how to confirm that the publishing workflow ran.
```

## Everyday use

1. Edit a file.
2. Run `quarto preview`, or click **Render** in RStudio.
3. Commit and push. The site republishes itself.

Everything works from a terminal, with no need to open RStudio. In the project folder:

```
quarto render                         # optional: build the whole site and catch errors before pushing
quarto preview                        # optional: open a live preview in your browser
git add -A
git commit -m "Describe the change"
git push
```

GitHub builds the site after every push, so pushing is all it takes to publish. The two `quarto` commands are for checking a change on your own computer first: `quarto render` builds the site once into `_site`, and `quarto preview` keeps a preview open that refreshes as you edit.

**New post.** Copy `post/_template` to `post/my_new_post`, edit `index.qmd` inside it, put pictures in the same folder, and delete the line `draft: true` when it is ready. The folder name becomes the address `/post/my_new_post/`.

**Schedule a post.** Give it a future `date:` and push. It stays off the site until that day, and the site rebuilds itself every night, so it appears by itself. `quarto preview` on your computer shows it at any time. To use a different time zone for "today", change `TIMEZONE` in `assets/schedule-posts.py`.

**Add a talk or a short course.** Add an entry to the list at the top of `talks/index.qmd` and push. Upcoming events are shown first, and each one moves to its own list by itself once its date has passed.

**Citation and download counts.** The Papers and Software pages show numbers kept in `_variables.yml`. Bioconductor downloads refresh by themselves at every build. Google Scholar answers requests from a personal computer only, so citations refresh when you run `Rscript assets/update-stats.R` on your computer (or click Source on that file in RStudio) and push. The papers and packages to track are listed in `assets/stats.json`.

**Update the CV and the resume.** The two PDFs are served from the site itself, from the `files/` folder, and the menu links point there. Run `bash assets/update-cv.sh` in the project folder: it builds both documents on your computer and copies the fresh PDFs into `files/`. Then commit and push. If a build fails, the script stops and the copies on the site stay as they are. The folders the script reads from are set in its first lines.

**Unpublish a post.** Move its folder from `post/` to `_drafts/`. That folder is never built and never sent to GitHub.

**If a build fails.** The Actions tab shows a red cross and the live site keeps its last good version. The cause is nearly always a typo in the block between the two `---` lines at the top of a `.qmd` file.

## What is in the repository

```
_quarto.yml              site settings: menu, footer, theme
index.qmd                home page
experience/ papers/ software/ talks/ awards/
                         one page each, in index.qmd
post/                    blog: one folder per post, plus the list page
assets/theme.scss        the look of the site
assets/theme-dark.scss   dark-mode colors
assets/fonts/            STIX Two Text, served from the site itself
assets/post-image.lua    shows a post's image above its text
assets/talks.lua         builds the lists on the Talks page
assets/schedule-posts.py holds back posts dated in the future
assets/update-stats.R    refreshes the citation and download counts
assets/update-cv.sh      builds the CV and resume and copies the PDFs into files/
files/                   the CV and resume PDFs that visitors download
_variables.yml           the saved counts
.github/workflows/       automatic publishing
```

## Reuse

The layout, styles and configuration are free to reuse for your own site. The text, photo and blog posts are Himel Mallick's own, so please replace them. The typeface is STIX Two Text, under the SIL Open Font License (see `assets/fonts`).
