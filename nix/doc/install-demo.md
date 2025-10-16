# Installation for Autobuild Test/Demo Sites

The script `bin/install-demo.sh` can be used to setup a web-host for long-running demo sites. It has a long docblock to
describe the general structure, prerequisites, and usage. Use those steps for setting up public or local instances.

The ultimate output of the script is a systemd unit called `demo.service`. This is a container-like environment (stored
in `~dispatcher/images/demo.img`) which runs all PHP/MySQL services.

After that, for the public service, there are some more steps (non-scripted) to setup DNS/SSL.

## Public Deployment: Cloudflare DNS/SSL

`install-demo.sh` has no innate implementation of DNS or SSL. For the public deployment, all sites are deployed
under `*.civi.bid` (*Cloudflare*). This serves a few purposes:

* The autobuild sites (`*.civi.bid`) live under a separate domain from production services (`*.civicrm.org`).
* This reduces the possibility of abusive, cross-domain interactions if someone submits malicious code to the autobuilder.
* This allows automatic setup of the wildcard SSL. (The webhost does not need any special API keys for manipulating DNS or managing SSL.)

When a request is sent from a web-browser to a demo site, the overall path looks like this:

```
+-------------+
| Web browser |
+-------------+
  |
  | [DNS, HTTPS]
  |
  |    +---------------------+
   \=> | Cloudflare Frontend |
       +---------------------+
         |
         | [proxy; HTTP over Cloudflare Tunnel]
         |
         |    +---------------------------------------+
          \=> | test-10 - demo-proxy [localhost:8888] |
              +---------------------------------------+
                |
                | [Internal HTTP]
                |
                |    +----------------------------+
                |\=> | demo, dfl [localhost:8001] |
                |    +----------------------------+
                |\=> | demo, min [localhost:8002] |
                |    +----------------------------+
                 \=> | demo, max [localhost:8003] |
                    +----------------------------+
```

The "Cloudflare Frontend" and "Cloudflare Tunnel" must be configured manually. However, they use wildcards, so they shouldn't
require much maintenance.

Here are some key elements in configuring this topology:

* On `test-10` (worker node), specify the preferred URLs for new builds by updating `/etc/bknix-ci/loco-overrides.yaml`:

    ```yaml
    - HTTPD_DOMAIN=civi.bid
    - "CIVIBUILD_URL_TEMPLATE=https://%SITE_NAME%.civi.bid"
    ```

* In the Cloudflare web UI, create a "Tunnel" to `test-10.civicrm.org`. Deploy `cloudflared` on `test-10`.

    * See: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-remote-tunnel/
    * Note the "Tunnel ID".

* In Cloudflare web UI, create a wildcard DNS record (`*.civi.bid CNAME <UUID>.cfargotunnel.com>`)

    * https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/routing-to-tunnel/dns/

* In Cloudflare web UI, update the "Tunnel" to set the  "Published Application" for `*.civi.bid` to point to `http://127.0.0.1:8888`
