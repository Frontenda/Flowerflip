module.exports = (tasks, choice, data, onResult) ->
  if typeof tasks is 'function'
    tasks = tasks choice, data

  state =
    finished: false
    fulfilled: []
    rejected: []
    choices: []
    countFulfilled: ->
      full = state.fulfilled.filter (f) -> typeof f isnt 'undefined'
      full.length
    countRejected: ->
      rej = state.rejected.filter (r) -> typeof r isnt 'undefined'
      rej.length
    isComplete: ->
      state.countFulfilled() + state.countRejected() is tasks.length
  return onFulfilled state unless tasks.length
  tasks.forEach (t, i) ->
    return if state.finished
    try
      val = t choice, data
      if val and typeof val.then is 'function' and typeof val.else is 'function'
        val.then (p, d) ->
          state.choices[i] = p
          state.fulfilled[i] = d
          p.continuation = val.tree.continuation
          choice.registerSubleaf p, true
          onResult state, d
        val.else (p, e) ->
          state.choices[i] = p
          state.rejected[i] = e
          p.continuation = val.tree.continuation
          choice.registerSubleaf p, false
          onResult state, e
        return
      state.fulfilled[i] = val
      onResult state, val
    catch e
      state.rejected[i] = e
      onResult state, e
