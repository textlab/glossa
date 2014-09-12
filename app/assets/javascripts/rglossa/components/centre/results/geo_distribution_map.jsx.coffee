###* @jsx React.DOM ###

window.GeoDistributionMap = React.createClass
  propTypes:
    data: React.PropTypes.object

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

    `<div>
      <Map initLat={62} initLon={6} initZoom={4} width={650} height={540} points={points} />
    </div>`
