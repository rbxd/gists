import json
import flask
import flask_saml
import flask_principal
from werkzeug.middleware.proxy_fix import ProxyFix
from dotenv import load_dotenv
import os

load_dotenv()

app = flask.Flask(__name__)

saml_metadata_url = os.getenv('SAML_METADATA_URL')

app.config.update({
    'PREFERRED_URL_SCHEME': 'https',
    'SAML_PREFIX': '/okta/saml',
    'SAML_DEFAULT_REDIRECT': '/okta/landing',
    'SECRET_KEY': 'soverysecret',
    'SAML_METADATA_URL': saml_metadata_url
})

app.wsgi_app = ProxyFix(
    app.wsgi_app, x_for=1, x_proto=1, x_host=1, x_prefix=1
)

principals = flask_principal.Principal(app)

flask_saml.FlaskSAML(app)

# App urls:
# /okta/saml/sso/
# /okta/saml/acs/
# /okta/saml/logout/

@flask_saml.saml_authenticated.connect_via(app)
def on_saml_authenticated(sender, subject, attributes, auth):
    # We have a logged in user, inform Flask-Principal
    flask_principal.identity_changed.send(
        flask.current_app._get_current_object(),
        identity=get_identity(),
    )

@flask_saml.saml_log_out.connect_via(app)
def on_saml_logout(sender):
    # Let Flask-Principal know the user is gone
    flask_principal.identity_changed.send(
        flask.current_app._get_current_object(),
        identity=get_identity(),
    )

# This provides the users' identity in the application
@principals.identity_loader
def get_identity():
    if 'saml' in flask.session:
        return flask_principal.Identity(flask.session['saml']['subject'])
    else:
        return flask_principal.AnonymousIdentity()


@flask_principal.identity_loaded.connect_via(app)
def on_identity_loaded(sender, identity):
    # If authenticated, you're an admin - yay!
    if not isinstance(identity, flask_principal.AnonymousIdentity):
        identity.provides.add(flask_principal.RoleNeed('admin'))

@app.route("/okta/landing")
def landing_page():
    user_identity = get_identity()
    res = ''

    if isinstance(user_identity, flask_principal.AnonymousIdentity):
        res = "Anonymous user<br/><br/>"
        res += f"<a href='{flask.url_for('login')}'>Login</a> <u>Logout</u>"
    else:
        res = f"Authenticated user: {flask.session['saml']}<br/><br/>"
        res += f"<u>Login</u> <a href='{flask.url_for('logout')}'>Logout</a>"
        return res

    return res


if __name__ == '__main__':
    app.run(debug=True, port=9293)
