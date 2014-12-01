#= require ./geo_distribution_map
#= require ./marker_picker

###* @jsx React.DOM ###

# MarkerSets - an array for all MarkerSet objects

class MarkerSets
  constructor: (@map) ->
    @sets = []
    @missing = []
    @infoWindow = null

  add: (tok, locas, color) ->
    if @sets[tok]
      @sets[tok].remove()
      @sets[tok].color = color
      @sets[tok].add()
    else
      set = new MarkerSet(@map, locas, tok, color)
      set.add()
      @sets[tok] = set
      for loc of set.noCoords
        @missing[loc] = 1

  hide: ->
    for j of @sets
      @sets[j].hide()

  show: ->
    for j of @sets
      @sets[j].show()

  remove: (tok) ->
    @sets[tok].remove() if @sets[tok]

  removeAll: ->
    for j of @sets
      @sets[j].remove()

  report: ->
    r = ""
    for e of @missing
      r += " " + e
    r

  closeInfoWindows: ->
    for j of @sets
      @sets[j].closeInfoWindow()


# MarkerSet - an object for groups of markers of same colour.

class MarkerSet
  constructor: (map, locas, tok, color) ->
    @map = map
    @locations = locas   # an array of locations for marker set
    @color = color       # the chosen marker color
    @tok = tok
    @markers = []        # array for all google marker objects in this set
    @noCoords = []


  createMarker: (latlng, map, color, contentString, loc) ->
    image = new google.maps.MarkerImage(
      "assets/rglossa/speech/mm_20_#{color}.png",
      new google.maps.Size(8, 13),    # size
      new google.maps.Point(0, 0),    # origin
      new google.maps.Point(4, 13),   # anchor
      new google.maps.Size(8, 13))    # size

    shadow = new google.maps.MarkerImage(
      "assets/rglossa/speech/mm_20_shadow.png",
      new google.maps.Size(12, 16),   # size
      new google.maps.Point(0, 0),    # origin
      new google.maps.Point(4, 13),   # anchor
      new google.maps.Size(12, 16))   # size

    infowindow = new google.maps.InfoWindow(content: contentString)

    marker = new google.maps.Marker
      position: latlng
      map: map
      icon: image
      shadow: shadow
      animation: google.maps.Animation.DROP
      title: loc

    google.maps.event.addListener marker, "click", ->
      MarkerSet.infoWindow.close() if MarkerSet.infoWindow?
      MarkerSet.infoWindow = infowindow
      infowindow.open map, marker

    marker


  closeInfoWindow: ->
    for j of @markers
      alert "closing: " + @markers[j].title
      if @markers[j].infoWindow
        alert "i have an infowindow!"
        @markers[j].infoWindow.close()


  makeMessage: (loc, tok) ->
    # TODO: Create message
    return ""

    infs1 = loc_inf[loc]
    infs2 = tok_inf[tok]
    infs = intersection(infs1, infs2)

    "Location: #{loc}<br />Phonetic: #{tok}<br />Informants: #{profileLink(infs)}"


  add: ->
    for loc in @locations
      unless coordinates[loc]
        @noCoord loc
        continue
      lat = coordinates[loc]["lat"]
      lng = coordinates[loc]["lng"]
      latlng = new google.maps.LatLng(lat, lng)
      marker = @createMarker(latlng, @map, @color, @makeMessage(loc, @tok), loc)
      @markers.push marker

  hide: ->
    for j of @markers
      @markers[j].setMap null
    true

  show: ->
    for j of @markers
      @markers[j].setMap map

  remove: ->
    for j of @markers
      @markers[j].setMap null
    @markers = []

  noCoord: (loc) ->
    @noCoords[loc] = 1

MarkerSet.infoWindow = null


window.GeoDistributionMapWindow = React.createClass
  propTypes:
    data: React.PropTypes.object

  loc_inf: []
  allMarkers: []

  componentDidUpdate: ->
    @markerSets = new MarkerSets(@refs.map.getMap())

  addMarker: (loca) ->
    dot = new google.maps.MarkerImage(
      "assets/red_dot.png",
      new google.maps.Size(4, 4),   # size
      new google.maps.Point(0, 0),  # origin
      new google.maps.Point(2, 2),  # anchor
      new google.maps.Size(4, 4))   # size

    unless coordinates[loca]
      document.getElementById("noCoords").innerHTML =
          "No coordinates found for: <b>#{loca}</b>"
      return loca

    lat = coordinates[loca]["lat"]
    lng = coordinates[loca]["lng"]

    latlng = new google.maps.LatLng(lat, lng)
    marker = new google.maps.Marker
      position: latlng
      map: map
      icon: dot

    allMarkers.push marker
    true


  addMarkers: (color, tok) ->
    if color is "#ddd"
      @markerSets.remove(tok)
      return

    locas = Object.keys(@props.data.phons_per_place[tok])
    i = 0
    noCoords = []
    @markerSets.add(tok, locas, color) # need to use this to remove, also!!!
    # @report @markerSets.missing


  # for reporting all missing coordinates
  report: (arr) ->
    empty = true

    unless arr[0]?
      for i of arr
        empty = false

    if empty
      document.getElementById("noCoords").innerHTML = ""
      return

    document.getElementById("noCoords").innerHTML = "Missing coordinates for: "
    for i of arr
      continue  if i is "unique"
      document.getElementById("noCoords").innerHTML += i + " "


  intersection: (arr1, arr2) ->
    is_ = []
    for j of arr1
      for i of arr2
        if arr1[j] is arr2[i]
          is_.push(arr1[j])
          break
    is_

  removePlots: ->
    @markerSets.removeAll()
    $(".colorpicker-trigger").css "background-color", "#ddd"

  hidePlots: ->
    @markerSets.hide()

  showPlots: ->
    @markerSets.show()

  clearMap: ->
    for j of allMarkers
      allMarkers[j].setMap null

  showAll: ->
    for j of allLocations
      addMarker allLocations[j]

  render: ->
    points = if @props.data
      (for key, value of @props.data.place_totals
        # TODO: Perhaps store coordinates in the database? We currently expect an application
        # using rglossa to define a global 'coordinates' object where the keys are location names
        # and the values are objects with 'lat' and 'lng' keys. A nice effect of this is that
        # it is easy to share coordinate values between applications (Glossa applications
        # as well as others), since all they have to do is load a JavaScript file that defines
        # such an object.
        # The downside is that the coordinates are not available on the server side, where we
        # we might want to use them e.g. for statistical calculations in the future. Hence, we
        # might want to move them to the database instead. We need to create tables that link
        # locations with speakers anyway (since the joins we do now in
        # SpeechCwbSearch#find_tids_to_places are far too costly when we have results from lots
        # of speakers), and then we could probably just store the coordinates in the locations
        # table.
        coord = coordinates[key]

        latitude: coord.lat
        longitude: coord.lng
        label: key)
    else []

    console.log(@props.data)

    `<div>
      <div style={{float: 'left'}}>
        <GeoDistributionMap ref="map" initLat={62} initLon={6} initZoom={4} width={650} height={540} points={points} />
      </div>
      <MarkerPicker data={this.props.data} addMarkers={this.addMarkers} />
    </div>`
