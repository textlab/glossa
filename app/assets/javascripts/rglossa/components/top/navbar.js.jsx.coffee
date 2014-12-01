###* @jsx React.DOM ###

window.Navbar = React.createClass
  render: ->
    `<div className="navbar navbar-fixed-top">
      <div className="navbar-inner" style={{paddingLeft: 10}}>
        <div className="container">
          <span className="brand">Glossa</span>
        </div>
      </div>
    </div>`