# jenkins-standalone
Run a Jenkins master on Apache Mesos and Marathon.

i run it with  marathon  Command is like below
     
     git clone https://github.com/mk-qi/jenkins-standalone.git &&cd jenkins-standalone;sh jenkins-standalone.sh -z $(cat /etc/mesos/zk)


=======================================cut line=========

<http://rogerignazio.com/blog/scaling-jenkins-mesos-marathon>.



## Usage
`jenkins-standalone.sh` takes two arguments:
  - ZooKeeper URL
  - Redis host

Redis is used as the broker for Logstash and the Jenkins Logstash plugin.

When copying/pasting this command into Marathon, each line should be
concatenated with `&&`, so that it only proceeds if the previous command
was successful.

Example usage:
```
git clone https://github.com/rji/jenkins-standalone
cd jenkins-standalone
./jenkins-standalone.sh -z $(cat /etc/mesos/zk) -r redis.example.com
```

You can also use the Marathon API to create apps. There is an example
`jenkins-standalone.json` in the `examples/` directory.

```
curl -i -H 'Content-Type: application/json' -d @jenkins-standalone.json marathon.example.com:8080/v2/apps
```
