# AutoDNS Module for ComputeStacks


#### Example:

Load a Zone
```
auth = AutoDNS::Auth.new(0, 'USER', 'PASS', 'CONTEXT')
client = AutoDNS::Client.new(nil, auth)
zone = AutoDNS::Dns::Zone.find(client, 'usr.cloud')
```

Create a Zone
```
auth = AutoDNS::Auth.new(0, 'USER', 'PASS', 'CONTEXT')
client = AutoDNS::Client.new(nil, auth)
zone = AutoDNS::Dns::Zone.new(client, nil)
zone.name = 'cmptstks.com'
zone.soa_email = 'dns@computestacks.com'
zone.default_ip = '62.116.130.8'
zone
```