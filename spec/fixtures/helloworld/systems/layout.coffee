layouts =
  simple: [
  ]
  directed: [
    require '../sections/post'
  ]

module.exports = (choice, data) ->
  tree = choice.continue 'layout'
  tree.deliver data
  .then 'user', (c, d) ->
    unless d.config.layout
      throw new Error 'No layout selected'
    unless layouts[d.config.layout]
      throw new Error "Unknown layout #{d.config.layout}"
    choice.set 'layout', d.config.layout
    c.addPath d.config.layout
    layouts[d.config.layout]
  .else 'derived', (c, d) ->
    layout = 'simple'
    c.addPath layout
    layouts[layout]
  .then (c, d) ->
    choice.set 'sections', d
    data
