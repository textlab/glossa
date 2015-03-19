###* @jsx React.DOM ###

window.Navbar = React.createClass
  render: ->
    idp_login_links = $.map login_urls, (url, idp) ->
      `<span className="navbar-text pull-right">
        <a href={url} className="navbar-link">Log in ({idp})</a>&nbsp;</span>`

    login_status = if username is ''
      `{idp_login_links}`
    else
      `<span className="navbar-text pull-right">Logged in as: {username}&nbsp;
        <a href={logout_url} className="navbar-link">Log out</a></span>`

    `<div className="navbar navbar-fixed-top">
      <div className="navbar-inner" style={{paddingLeft: 10}}>
        <div className="container">
          <span className="brand">Glossa</span>
          {login_status}
        </div>
      </div>
    </div>`
