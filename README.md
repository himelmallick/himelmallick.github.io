# himelmallick.github.io

Personal website of Himel Mallick, built with [Quarto](https://quarto.org). Edit a file, push to GitHub, and the site rebuilds and publishes itself in about two minutes.

## Update the site

1. Open `himelmallick.github.io.Rproj` in RStudio and edit the file (see the table).
2. Click **Render** to preview.
3. In the **Git** tab: tick the changed files, **Commit**, then **Push**.

## Where things are

| To change | Edit |
|---|---|
| Name, tagline, biography, research areas, profile links, lab video | `index.qmd` |
| Main photo (600 x 900 pixels) | `assets/himel-mallick.jpg` |
| Jobs and skills | `experience/index.qmd` |
| Notable Papers | `papers/index.qmd` |
| Notable Software | `software/index.qmd` |
| Honors and Awards | `awards/index.qmd` |
| A blog post | `post/<name>/index.qmd` |
| Menu, footer, CV and Resume links | `_quarto.yml` |
| Colors and type | `assets/theme.scss`, `assets/theme-dark.scss` |

To add a paper, software package or award, copy an existing entry in that file and change it.

## Posts

**New post.** Copy `post/_template` to `post/my_new_post`, edit `index.qmd` inside it, put pictures in the same folder, and delete the line `draft: true` when it is ready. The folder name becomes the address `/post/my_new_post/`.

**Unpublish a post.** Move its folder from `post/` to `_drafts/`. That folder is never built and never sent to GitHub.

## First push (once)

1. On GitHub: repository Settings, Pages, set Source to **GitHub Actions**.
2. Create a token in the R console:

   ```r
   usethis::create_github_token()
   gitcreds::gitcreds_set()
   ```

3. In the RStudio Terminal:

   ```
   git init -b master
   git remote add origin https://github.com/himelmallick/himelmallick.github.io
   git add --all
   git commit -m "Rebuild site with Quarto"
   git push -f origin master
   ```

4. Watch the Actions tab on GitHub. A green check means the site is live.

## If a build fails

The Actions tab shows a red cross and the live site keeps its last good version. The cause is nearly always a typo in the block between the two `---` lines at the top of a `.qmd` file. Fix it and push again.
