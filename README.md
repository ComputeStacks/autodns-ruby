# AutoDNS Module for ComputeStacks


#### Example:

Load a Zone
```ruby
auth = AutoDNS::Auth.new(0, 'computestacks', 'cKbXf82b2HgRSLwA', '33004')
client = AutoDNS::Client.new(nil, auth)
zone = AutoDNS::Dns::Zone.find(client, 'computestacks.es')
```

Create a Zone
```ruby
auth = AutoDNS::Auth.new(0, 'computestacks', 'cKbXf82b2HgRSLwA', '33004')
client = AutoDNS::Client.new(nil, auth)
zone = AutoDNS::Dns::Zone.new(client, nil)
zone.name = 'cmptstks.com'
zone.soa_email = 'dns@computestacks.com'
zone.default_ip = '62.116.130.8'
zone
```