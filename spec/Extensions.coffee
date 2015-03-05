chai = require 'chai' unless chai
Choice = require '../lib/Choice'
# {State, ensureActive} = require '../lib/state'
Root = require '../lib/Root'

describe 'Extensions', ->

  describe 'branch safe global asset registration', ->

    {ensureActive, State} = Choice

    class CustomChoice extends Choice

      constructor: () ->
        super arguments...
        @attributes._assets = []
        @
      createChoice: (source, id, name) ->
        new CustomChoice source, id, name

      registerSubleaf: (leaf, accepted, consumeWithoutContinuation = true) ->
        super leaf, accepted, consumeWithoutContinuation
        return unless accepted
        assets = leaf.registeredAssets false
        @registerAsset a, false for a in assets

      registerAsset: (asset, checkActive = true) ->
        ensureActive @ if checkActive
        throw new Error 'No asset provided' unless asset
        id = asset.id
        if !id?
          @attributes._assets.push asset
        else
          assets = @registeredAssets()
          for a, i in assets
            return asset if a.id is id # move along if asset id is taken
          @attributes._assets.push asset
        asset

      registeredAssets: (followParent = true) ->
        # gather assets above and at choice node
        if @source
          assets = @source.registeredAssets()
          assets = assets.concat @attributes._assets if @attributes._assets.length
        else if @parentSource and followParent
          assets = @parentSource.registeredAssets()
          assets = assets.concat @attributes._assets if @attributes._assets.length
        else
          assets = @attributes._assets
        assets

      getAssets: (callback) ->
        assets = @registeredAssets()
        return null unless assets.length
        return null unless typeof callback is 'function'
        results = []
        for asset in assets
          try
            ret = callback asset
            results.push(asset) if ret
          catch e
            continue
        return results if results.length > 0
        null

    it 'should extend choice', (done) ->
      Root 'asset-test', Choice:CustomChoice
      .deliver()
      .finally (c) ->
        chai.expect(c.attributes).to.be.ok
        chai.expect(c.attributes._assets).to.be.ok
        chai.expect(c.registerAsset).to.be.ok
        done()

    it '1 level asset registration', (done) ->
      Root 'asset-test', Choice:CustomChoice
      .deliver()
      .then (c) ->
        c.registerAsset
          id: 'display-font-css'
          type: 'css-file'
          data: './didot.css'
      .then (c) ->
        c.registerAsset
          id: 'display-font-css'
          type: 'css-file'
          data: './arial.css'
      .then (c) ->
        c.registerAsset
          id: 'body-font-css'
          type: 'css-file'
          data: './georgia.css'
      .then (c) ->
        c.getAssets (asset) ->
          asset.type is 'css-file'
        .map (asset) ->
          asset.data
      .finally (c, files) ->
        chai.expect(files).to.eql ['./didot.css','./georgia.css']
        done()

    it '2 level asset registration', (done) ->
      ###
      assets registered by child should not be overwritten by parent
      ###
      child = (parent) ->
        parent.tree('child')
        .deliver()
        .then 'display-font', (c) ->
          c.registerAsset
            id: 'display-font-css'
            type: 'css-file'
            data: './didot.css'
        .then 'body-font', (c) ->
          c.registerAsset
            id: 'body-font-css'
            type: 'css-file'
            data: './georgia.css'
      Root 'asset-test', Choice:CustomChoice
      .deliver {}
      .then 'start', ->
        true
      .then child
      .then 'ignored-font', (c) ->
        c.registerAsset
          id: 'display-font-css'
          type: 'css-file'
          data: './arial.css'
      .then 'build', (c) ->
        c.getAssets (asset) ->
          asset.type is 'css-file'
        .map (asset) ->
          asset.data
      .finally (c, files) ->
        chai.expect(files).to.eql ['./didot.css','./georgia.css']
        done()


    it '3 level asset registration', (done) ->
      ###
      assets registered by child should not be overwritten by parent
      ###
      grandchild = (parent) ->
        parent.tree('child')
        .deliver()
        .then 'display-font', (c) ->
          c.registerAsset
            id: 'display-font-css'
            type: 'css-file'
            data: './didot.css'

      child = (parent) ->
        parent.tree('child')
        .deliver()
        .then grandchild
        .then 'ignored-font', (c) ->
          c.registerAsset
            id: 'display-font-css'
            type: 'css-file'
            data: './comic-sans.css'
        .then 'body-font', (c) ->
          c.registerAsset
            id: 'body-font-css'
            type: 'css-file'
            data: './georgia.css'
      Root 'asset-test', Choice:CustomChoice
      .deliver {}
      .then 'start', ->
        true
      .then child
      .then 'ignored-font', (c) ->
        c.registerAsset
          id: 'display-font-css'
          type: 'css-file'
          data: './arial.css'
      .then 'build', (c) ->
        c.getAssets (asset) ->
          asset.type is 'css-file'
        .map (asset) ->
          asset.data
      .finally (c, files) ->
        chai.expect(files).to.eql ['./didot.css','./georgia.css']
        done()
