$.fn.flexBoxes = (options) ->
  settings =
    height: -> window.innerHeight
    flexBoxSelector: ">*"
    throttleResizeMs: 100
    minHeight: 30
    animationSpeed: 500
    activateDelay: 150
    deactivateDelay: 800
    clickOnly: false
  $.extend settings, options

  $container = $ @
  $flexBoxes = $container.find settings.flexBoxSelector
  flexBoxCount = $flexBoxes.length
  $body = $ "body"
  activateTimer = deactivateTimer = throttleTimer = maxHeight = boxPadding = null
  needRestoreBox = active = false
  # helpers

  reset = ->
    $flexBoxes = $container.find settings.flexBoxSelector
    flexBoxCount = $flexBoxes.length
    $box = $(".current")
    $flexBoxes.data("originalHeight", null).data("resizedHeight", null).stop().css("height", "auto").removeClass("current")
    resizeDivs $box
  cantFitTheContainer = (containerHeight) ->
    height = 0
    $flexBoxes.each ->
      $box = $ @
      unless $box.data("originalHeight")
        boxHeight = $box.height()
        $box.data "originalOuterHeight", $box.outerHeight(true)
        $box.data "resizedHeight", $box.outerHeight(true)
        $box.data "originalHeight", boxHeight
      height += $box.data("originalOuterHeight")
    boxPadding = $flexBoxes.data("originalOuterHeight") - $flexBoxes.data("originalHeight")
    height > containerHeight
  resizeDivs = ($openBox) ->
    containerHeight = remainingHeight = settings.height()
    active = cantFitTheContainer containerHeight
    if active
      maxHeight = remainingHeight - settings.minHeight * (flexBoxCount - 1)
      [$_flexBoxes, averageHeight] = resizeBoxes(remainingHeight)
      $_flexBoxes.data("resizedHeight", averageHeight)
      if $openBox.length
        expandBox $openBox, 50
      else
        $_flexBoxes.stop(true).animate { height: averageHeight, scrollTop: 0 }, settings.animationSpeed
    else
      $flexBoxes.each ->
        $box = $ @
        $box.height $box.data("originalHeight")

  resizeBoxes = (remainingHeight) ->
    $_flexBoxes = $container.find "#{settings.flexBoxSelector}:not(.current)"
    averageHeight = undefined
    needsResize = true
    while needsResize
      averageHeight = Math.floor(remainingHeight / $_flexBoxes.length)
      needsResize = false
      $_flexBoxes = $_flexBoxes.filter((i, arr) ->
        $this = $(this)
        height = $this.data("originalOuterHeight")
        if height > averageHeight
          true
        else
          $this.stop(true).animate {height: $this.data("originalOuterHeight")}, settings.animationSpeed
          remainingHeight -= height
          needsResize = true
          false
      )
    [$_flexBoxes, averageHeight]

  # actions

  restoreBoxes = ->
    speed = Math.floor(settings.animationSpeed / $flexBoxes.length)
    $flexBoxes.each ->
      $box = $ @
      $flexBoxes.queue (next) ->
        $box.stop(true).removeClass("current").animate
          height: $box.data("resizedHeight")
          scrollTop: 0
        , speed, -> next()
    $flexBoxes.dequeue()

  expandBox = ($el, speed) ->
    speed = speed || settings.animationSpeed
    newHeight = Math.min $el.data("originalOuterHeight"), maxHeight
    $flexBoxes.removeClass("current")
    $el.addClass("current").stop(true).animate({height: newHeight, scrollTop: 0 }, speed, -> $(@).css "overflow-y", "auto")
    [$_flexBoxes, averageHeight] = resizeBoxes settings.height() - newHeight
    $_flexBoxes.stop(true).animate { height: averageHeight, scrollTop: 0 }, speed

  # commands

  activate = ->
    cancelTimers()
    if active
      $this = $(this)
      needRestoreBox = true
      $flexBoxes.css "overflow-y", "hidden"
      $body.addClass "no-scroll"
      expandBox $this

  activateDelayed = ->
    cancelTimers()
    activateTimer = setTimeout =>
      activate.call @
    , settings.activateDelay

  deactivateDelayed = ->
    cancelTimers()
    if active
      $body.removeClass "no-scroll"
      $flexBoxes.css "overflow-y", "hidden"
      if needRestoreBox
        needRestoreBox = false
        deactivateTimer = setTimeout restoreBoxes, settings.deactivateDelay

  cancelTimers = ->
    clearTimeout deactivateTimer if deactivateTimer
    clearTimeout activateTimer if activateTimer

  # bind events

  window.addEventListener "resize", ->
    clearTimeout(throttleTimer) if throttleTimer
    throttleTimer = setTimeout reset, settings.throttleResizeMs

  $flexBoxes.mouseenter(activateDelayed) if not settings.clickOnly
  $container.mouseenter -> clearTimeout deactivateTimer if deactivateTimer
  $container.mouseleave deactivateDelayed
  $flexBoxes.click activate
  reset()
