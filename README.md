# matrix-synapse-riot-k8s
Secure Homeserver for Riot on Kubernetes


![alt text](https://github.com/gokulpch/matrix-synapse-riot-k8s/blob/master/media/riot1.png)

![alt text](https://github.com/gokulpch/matrix-synapse-riot-k8s/blob/master/media/riot2.png)

![alt text](https://github.com/gokulpch/matrix-synapse-riot-k8s/blob/master/media/riot3.png)


### Generating Keys and Certs


##### Setup Keys and Certs for Matrix-Synapse Server

* Can be swapped if a user have own certs, Use certbot or lets-encrypt if user has a DNS resolvable name.

```
sudo apt-get update
sudo apt-get install software-properties-common
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update
sudo apt-get install python-certbot-nginx

sudo certbot certonly --authenticator standalone --pre-hook "nginx -s stop" --post-hook "nginx" -d <my.domain.name>

-> Generating a dhparam: openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
```

* The script below opens the 'homeserver.yaml' file for editing change the parameters as necessary.

```
    tls_certificate_path: "/synapse/tls/tls.crt"

    # PEM encoded private key for TLS
    tls_private_key_path: "/synapse/tls/tls.key"

    # PEM dh parameters for ephemeral keys
    tls_dh_params_path: "/synapse/keys/ves.riot.io.tls.dh"

    # Don't bind to the https port
    no_tls: False
    
    # Database configuration
    database:
      # The database engine name
      name: "sqlite3"
      # Arguments to pass to the engine
      args:
        # Path to the database
        database: "/synapse/data/homeserver.db"

    # Number of events to cache in memory.
    event_cache_size: "10K"
    
    # Enables ReCaptcha checks when registering, preventing signup
    # unless a captcha is answered. Requires a valid ReCaptcha
    # public/private key.
    enable_registration_captcha: False
    
    # Enable registration for new users.
    enable_registration: False
```

```
$:~/new-dev/matrix-synapse/kubernetes# ./setup/setup-key.sh

Enter the server name of the Synapse instance: example-server
Enter the namespace for the Matrix instance: example-ns
Generating configuration...
> python -m synapse.app.homeserver -c /synapse/config/homeserver.yaml --generate-config --report-stats yes -H example-server
A config file has been generated in '/synapse/config/homeserver.yaml' for server name 'example-server' with corresponding SSL keys and self-signed certificates. Please review this file and customise it to your needs.
If this server name is incorrect, you will need to regenerate the SSL certificates
Make sure to look throught the generated homeserver yaml, check that everything looks correct before launching your Synapse.
```

* The script above creates the following keys and certs mentioned below
```
$:~/new-dev/matrix-synapse/kubernetes# ls /tmp/tmp.g1W5n9Dhv8/config/

example-server.signing.key  example-server.tls.crt  example-server.tls.dh  example-server.tls.key  homeserver.yaml  log.yaml
```

* Create Kubernetes Configmap and Security Resources

```
kubectl create ns matrix-test
kubectl --namespace=matrix-test create secret tls matrix-synapse-tls --cert="example-server.tls.crt" --key="example-server.tls.key"
kubectl --namespace=matrix-test create secret generic matrix-synapse-key --from-file=example-server.tls.dh="dfs.tls.dh" --from-file=signing.key="example-server.signing.key"
kubectl --namespace=matrix-test create configmap matrix-synapse --from-file=homeserver.yaml="homeserver.yaml"
kubectl --namespace=matrix-test create configmap matrix-synapse-log --from-file=log.yaml="log.yaml"

```

```
$# kubectl get cm,secrets,all -n matrix-test
NAME                           DATA   AGE
configmap/matrix-synapse       1      3h51m
configmap/matrix-synapse-log   1      171m

NAME                         TYPE                                  DATA   AGE
secret/default-token-5n9cp   kubernetes.io/service-account-token   3      3h56m
secret/matrix-synapse-key    Opaque                                2      169m
secret/matrix-synapse-tls    kubernetes.io/tls                     2      3h55m

NAME                                  READY   STATUS    RESTARTS   AGE
pod/matrix-synapse-599cd7778b-msp7m   1/1     Running   0          143m


NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
service/matrix-synapse               ClusterIP   10.102.21.249   <none>        8008/TCP,8448/TCP   119m
service/matrix-synapse-replication   ClusterIP   10.106.247.95   <none>        9092/TCP            119m


NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/matrix-synapse   1/1     1            1           143m

NAME                                        DESIRED   CURRENT   READY   AGE
replicaset.apps/matrix-synapse-599cd7778b   1         1         1       143m
```
