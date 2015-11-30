###* @jsx React.DOM ###

window.Navbar = React.createClass
  render: ->
    idp_login_links = $.map login_urls, (url, idp) ->
      `<span className="navbar-text pull-right">
        <a href={url} className="navbar-link">Log in ({idp})</a>&nbsp;</span>`

    login_status = if username is ''
      idp_login_links
    else
      `<span className="navbar-text pull-right"><b>Logged in as</b>: {displayName}&nbsp;
        <a href={logout_url} className="navbar-link"><b>Log out</b></a></span>`

    `<div className="navbar navbar-fixed-top">
      <div className="navbar-inner" style={{paddingLeft: 10}}>
        <div className="container">
          <span className="brand">Glossa</span>
          {login_status}
          <div className="pull-right">
            <img src="assets/clarino_duo-219.png" style={{marginTop: 10, width: 80}}></img>
            <img src="assets/logo.png" style={{marginTop: 2}}></img>
            </div>
        </div>
      </div>
    </div>`
