# AutoDNS Module for ComputeStacks

## Building

```bash
gem build autodns.gemspec
gem push --key github --host https://rubygems.pkg.github.com/ComputeStacks autodns-*.gem
```

#### Examples:


```ruby
##
# Load a Zone

auth = AutoDNS::Auth.new(0, 'USER', 'PASS', 'CONTEXT')
client = AutoDNS::Client.new(nil, auth)
zone = AutoDNS::Dns::Zone.find(client, 'kwtester.net')

##
# Create a Zone
zone = AutoDNS::Dns::Zone.new(client, nil)
zone.name = 'cmptstks.com'
zone.soa_email = 'dns@computestacks.com'
zone.default_ip = '62.116.130.8'
zone

```
