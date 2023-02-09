# BorgServer - Container image

Debian based container image, running openssh-daemon only accessable by user named "borg" using SSH-Publickey Auth & "borgbackup" as client.

For every ssh-key added, a own borg-repository will be created.

This Image is meant to run in Kubernetes. If you are looking for a Docker/Standalone solution, check out the previous Image [here](https://github.com/Nold360/docker-borgserver).

## Quick Example

Here is a quick example how to configure & run this image:

### Create persistent keys storage

```bash
mkdir -p borg/keys/client
```

Make sure that the permissions are right on the keys folder:

```bash
chown 1000:1000 borg/keys
```

### (Generate &) Copy every client's ssh publickey into persistent storage

*Remember*: Filename = Borg-repository name!

```bash
cp ~/.ssh/my_machine.pub borg/keys/client/my_machine
```

The OpenSSH-Deamon will expose on port 22/tcp - so you will most likely want to redirect it to a different port. Like in this example:

```bash
docker run -td \
    -p 2222:22 \
    --volume ./borg/keys:/keys \
    --volume ./borg/backup:/backup \
    ghcr.io/dzervas/docker-borgserver:latest
```

## Borgserver Configuration

- Place Borg-Clients SSH-PublicKeys in persistent storage
- Client backup-directories will be named by the filename found in /keys/client/

### Environment Variables

#### BORG_SERVE_ARGS

Use this variable if you want to set special options for the "borg serve"-command, which is used internally.

See the the documentation for all available arguments: [borgbackup.readthedocs.io](https://borgbackup.readthedocs.io/en/stable/usage.html#borg-serve)

##### Example

```bash
docker run --rm -e BORG_SERVE_ARGS="--progress --debug" (...) ghcr.io/dzervas/docker-borgserver:latest
```

#### BORG_APPEND_ONLY

If you want your client to be only able to append & not prune anything from their repo, set this variable to **"yes"**.

#### BORG_ADMIN

When *BORG_APPEND_ONLY* is active, no client is able to prune it's repo.
Since you might want to cleanup the repos at some point, you can declare one client to be the borg "admin".

This client will have **full access to all repos of any client!** So he's able to add/prune/... what ever he wants.

To declare a client as admin, set this variable to the name of the client/sshkey you've added to the /sshkeys/clients directory.

##### Example

```bash
docker run --rm -e BORG_APPEND_ONLY="yes" -e BORG_ADMIN="nolds_notebook" (...) ghcr.io/dzervas/docker-borgserver:latest
```

To prune repos from another client, you have to add the path to the repository in the clients directory:

```bash
borg prune --keep-last 100 --keep-weekly 1 (...) borgserver:/clientA/clientA
```

#### PUID

Used to set the user id of the `borg` user inside the container. This can be useful when the container has to access resources on the host with a specific user id.

#### PGID

Used to set the group id of the `borg` group inside the container. This can be useful when the container has to access resources on the host with a specific group id.

### Persistent Storages & Client Configuration

We will need two persistent storage directories for our borgserver to be usefull.

#### /keys

This directory has two subdirectories:

##### /keys/client/

Here we will put all SSH public keys from our borg clients, we want to backup. Every key must be it's own file, containing only one line, with the key. The name of the file will become the name of the borg repository, we need for our client to connect.

That means every client get's it's own repository. So you might want to use the hostname of the client as the name of the sshkey file.

Hidden files & files inside of hidden directories will be ignored!

```bash
e.g. /keys/client/webserver.mydomain.com
```

Than your client would have to initiat the borg repository like this:

```bash
webserver.mydomain.com ~$ borg init ssh://borg@borgserver-container/backup/webserver.mydomain.com/my_first_repo
```

**!IMPORTANT!**: The container wouldn't start the SSH-Deamon until there is at least one ssh-keyfile in this directory!

##### /keys/host/

This directory will be automaticly created on first start. Also run.sh will copy the SSH-Hostkeys here, so your clients can verify it's borgservers ssh-hostkey.

#### /backup

In this directory will borg write all the client data to. It's best to start with an empty directory.


## Example Setup

### docker-compose.yml

Here is a quick example, how to run borgserver using docker-compose:

```yaml
services:
 borgserver:
  image: ghcr.io/dzervas/docker-borgserver:latest
  volumes:
   - /backup:/backup
   - ./sshkeys:/sshkeys
  ports:
   - "2222:22"
  environment:
   BORG_SERVE_ARGS: ""
   BORG_APPEND_ONLY: "no"
   BORG_ADMIN: ""
   PUID: 1000
   PGID: 1000
```

### ~/.ssh/config for clients

With this configuration (on your borg client) you can easily connect to your borgserver.

```config
Host backup
	Hostname my.docker.host
	Port 2222
	User borg
```

Now initiate a borg-repository like this:

```bash
borg init backup:my_first_borg_repo
```

And create your first backup!

```bash
borg create backup:my_first_borg_repo::documents-2017-11-01 /home/user/MyImportentDocs
```
