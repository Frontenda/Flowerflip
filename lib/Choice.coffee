class Choice
  constructor: (source, id) ->
    unless id
      id = source
      source = null
    unless id
      throw new Exception 'Choice ID required'

    @id = id
    @source = source
    @onBranch = null

    @path = if @source then @source.path.slice(0) else []
    @path.push id

    @attributes =
      items: []
      itemsEaten: []
      blocksEaten: []

  branch: (id, callback = ->) ->
    unless typeof @onBranch is 'function'
      throw new Error 'Cannot branch without external onBranch'
    branch = new Choice @source, id
    clone = @toJSON()
    for key, val of clone
      continue if key in ['path', 'id']
      branch.attributes[key] = val

    @onBranch @, branch, callback

    branch

  getItem: (callback) ->
    items = @availableItems()
    return null unless items.length

    unless typeof callback is 'function'
      return items[0]

    for item in items
      try
        callback item
        return item
      catch e
        continue
    null

  eatItem: (item, node = null) ->
    throw new Error 'No item provided' unless item
    @attributes.itemsEaten.push item

  availableItems: ->
    # Get original list of nodes
    if @source
      items = @source.availableItems()
      items = items.concat @attributes.items if @attributes.items.length
    else
      items = @attributes.items

    # Filter out the ones we've eaten
    items.filter (i) =>
      @attributes.itemsEaten.indexOf(i) is -1

  getBlock: (item, callback) ->
    return null unless item.content?.length
    blocks = @availableBlocks item
    return null unless blocks.length

    unless typeof callback is 'function'
      return blocks[0]

    for block in blocks
      try
        callback block
        return block
      catch e
        continue
    null

  eatBlock: (block, node = null) ->
    @attributes.blocksEaten.push block
    # TODO: Auto-mark item as eaten when all necessary blocks are consumed

  availableBlocks: (item) ->
    blocks = if @source then @source.availableBlocks(item) else item.content
    blocks.filter (b) =>
      @attributes.blocksEaten.indexOf(b) is -1

  toJSON: ->
    base =
      id: @id
      path: @path

    for key, val of @attributes
      if typeof val.slice is 'function'
        base[key] = val.slice 0
        continue
      base[key] = val

    base

  toString: -> @path.join '-'

module.exports = Choice
