# AutoDNS Module for ComputeStacks

This currently ONLY supports reverse DNS (PTR) records.

```
auth = Autodns::Auth.new(0, 'user', 'password', 'context')
client = Autodns::Client.new('https://gateway.autodns.com', auth)
zone = Autodns::Dns::Zone.new(client, '0.0.11.in-addr.arpa')
record = Autodns::Dns::ZoneRecord.new(client, nil, nil)
record.type = 'PTR'
record.name = '55'
record.value = 'something.net'
zone.records['PTR'] << record
```
