# Docker-Nagios

Docker image for Nagios

Nagios Core 4.5.2 running on Ubuntu 20.04 LTS with NagiosGraph, NRPE, NCPA, NSCA, and NRDP.

| Product | Version |
| ------- | ------- |
| Nagios Core | 4.5.2 |
| Nagios Plugins | 2.4.10 |
| NRPE | 4.1.0 |
| NCPA | 3.0.2 |
| NSCA | 2.10.2 |
| NRDP | 2.0.5 |


### Configurations

* Nagios configuration lives in /opt/nagios/etc
  * Custom plugins live in /opt/nagios/custom-plugins
  * MIB files live in /opt/nagios/mibs
* NagiosGraph configuration lives in /opt/nagiosgraph/etc
* NRDP server configuration lives in /opt/nrdp/server

### Install

Download the default image from Docker Hub by running:

```sh
docker pull run2000/nagios:latest
```

Alternatively, you can build the image from GitHub:

```sh
git clone https://github.com/run2000/Docker-Nagios.git 

cd Docker-Nagios
docker build -t nagios .
```
Additional build arguments may be passed into the Dockerfile at build time. The following sections describe these.

#### Operating System

This build argument specifies the Ubuntu base image on top of which the rest of the image is built. Change this at your own risk.

| Build Arg | Default Value | Description |
| ------- | ------- | ------ |
| UBUNTU_VERSION | 20.04 | Ubuntu Focal LTS release image |

#### Release versions

These build arguments configure the versions of each component that are fetched and installed.

| Build Arg | Default Value | Description |
| ------- | ------- | ------ |
| NAGIOS_VER | 4.5.2 | The Nagios Core release version |
| NAGIOS_PLUGINS_VER | 2.4.10 | The Nagios Plugins release version |
| NRPE_VER | 4.1.0 | The NRPE release version |
| NCPA_VER | 3.0.2 | The NCPA release version |
| NSCA_VER | 2.10.2 | The NSCA release version |
| NRDP_VER | 2.0.5 | The NRDP release version |

#### Default environment

These build arguments configure default Nagios behaviour. They can be overridden by environment variables when starting the container.

| Build Arg | Default Value | Description |
| ------- | ------- | ------ |
| NAGIOS_FQDN | nagios.example.com | The server Fully Qualified Domain Name in Postfix |
| NAGIOS_TIMEZONE | UTC | The timezone of the server |
| NAGIOSADMIN_USER | nagiosadmin | The admin user name for the web interface |
| NAGIOSADMIN_PASS | nagios | The admin password for the web interface |

#### NRDP configuration

These build arguments configure the default NRDP behaviour.

| Build Arg | Default Value | Description |
| ------- | ------- | ------ |
| NRDP_ENABLED | 1 | Enable NRDP through the Apache 2 configuration. |
| NRDP_TOKEN | | A token that may be used for NRDP requests. |

NRDP may be disabled by setting NRDP_ENABLED to any other value.

If NRDP_TOKEN is unspecified, no tokens will be configured.


### Running

Run with the example configuration with the following:

```sh
docker run --name nagios4 -p 0.0.0.0:8080:80 run2000/nagios:latest
```

alternatively you can use external Nagios configuration & log data with the following:

```sh
docker run --name nagios4  \
  -v /path-to-nagios/etc/:/opt/nagios/etc/ \
  -v /path-to-nagios/var:/opt/nagios/var/ \
  -v /path-to-custom-plugins:/opt/nagios/custom-plugins \
  -v /path-to-custom-mib-files:/opt/nagios/mibs \
  -v /path-to-nagiosgraph-var:/opt/nagiosgraph/var \
  -v /path-to-nagiosgraph-etc:/opt/nagiosgraph/etc \
  -v /path-to-nrdp-server:/opt/nrdp/server \
  -p 0.0.0.0:8080:80 run2000/nagios:latest
```

Note: The path for the custom plugins will be /opt/nagios/custom-plugins, you will need to reference this directory in your configuration scripts.

There are a number of environment variables that you can use to adjust the behaviour of the container:

| Environment Variable | Description |
|--------|--------|
| MAIL_RELAY_HOST | Set Postfix relayhost |
| MAIL_INET_PROTOCOLS | Set the inet_protocols in Postfix |
| NAGIOS_FQDN | Set the server Fully Qualified Domain Name in Postfix |
| NAGIOS_TIMEZONE | Set the timezone of the server |
| NAGIOSADMIN_USER | Set the admin user name for the web interface |
| NAGIOSADMIN_PASS | Set the admin password for the web interface |

For best results your Nagios image should have access to both IPv4 & IPv6 networks 

#### Credentials

The default credentials for the web interface is `nagiosadmin` / `nagios`

To change this:

* Set the NAGIOSADMIN_USER and NAGIOSADMIN_PASS environment variables
* Update the /opt/nagios/etc/cgi.cfg file and update the authorized_for_* parameters to point add the new admin user
* Delete the /opt/nagios/etc/htpasswd.users file. This will be re-generated when the container is started.

### Extra Plugins

* Nagiosgraph [<http://exchange.nagios.org/directory/Addons/Graphing-and-Trending/nagiosgraph/details>]
* Nagios Cross-Platform Agent (NCPA) [<https://github.com/NagiosEnterprises/ncpa>]
* Nagios Remote Plugin Executor (NRPE) [<https://github.com/NagiosEnterprises/nrpe>]
* Nagios Service Check Acceptor (NSCA) [<https://github.com/NagiosEnterprises/nsca>]
* Nagios Remote Data Processor (NRDP) [<https://github.com/NagiosEnterprises/nrdp>]

### Credits

* This Docker image is based on the project at <https://github.com/JasonRivers/Docker-Nagios>
* Some improvements came from the project <https://github.com/tronyx/Docker-Nagios>
