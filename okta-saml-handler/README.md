## Set up app in okta

## Fill in SAML metadata URL in .env

## Set up nginx forwarding:
```
  location /okta {
    proxy_pass http://127.0.0.1:9293;
    proxy_redirect      off;
    proxy_set_header    Host             $host;
    proxy_set_header    X-Real-IP        $remote_addr;
    proxy_set_header    X-Forwarded-For  $proxy_add_x_forwarded_for;
    proxy_set_header    X-Forwarded-Proto $scheme;
    proxy_set_header    X-Forwarded-Host $host;
  }
```

## Run the app
```
virtualenv venv
source ./venv/bin/activate
pip -r install requirements.txt

python app.py
```
