#= require ./navbar
#= require ./main_area

###* @jsx React.DOM ###

window.App = React.createClass
  render: ->
    `<span>
      <Navbar/>
      <MainArea/>
    </span>`
