-- Shows a post's `image:` at the top of the post, so one line of front matter
-- sets both the social-sharing card and the picture above the text.
-- Add `show-image: false` to a post to keep the image out of the page.
function Pandoc(doc)
  local img = doc.meta.image
  if img == nil or doc.meta["show-image"] == false then
    return doc
  end
  local src = pandoc.utils.stringify(img)
  local alt = ""
  if doc.meta["image-alt"] then
    alt = pandoc.utils.stringify(doc.meta["image-alt"])
  end
  local picture = pandoc.Image({}, src, "", pandoc.Attr("", {"post-lead-image"}, {alt = alt}))
  table.insert(doc.blocks, 1, pandoc.Div({pandoc.Plain({picture})}, pandoc.Attr("", {"post-lead"})))
  return doc
end
