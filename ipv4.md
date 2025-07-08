IPv4 is a 32-bit binary number written in decimal-dotted notation for readability.

ip2bin()
--------
IP address: 128.42.5.4

IP binary: 10000000 00101010 00000101 00000100

Usage: ip2bin 128.42.5.4

bin2ip()
--------
IP binary: 10000000 00101010 00000101 00000100

IP address: 128.42.5.4

Usage: bin2ip '10000000 00101010 00000101 00000100'

cidr2netmask()
--------------
The netmask tells which part of the IP address is the network address (and which is host address).

Netmask: 255.255.248.0

In binary: 11111111 11111111 11111000 00000000

There are 21 ones: this is the netmask length.

Thus, in CIDR notation, 128.42.5.4/21 => 21 bits are network bits and the last 11 are host bits.

Usage: cidr2netmask 128.42.5.4/21  # returns 255.255.248.0

cidr2network()
--------------
To obtain the network address of 128.42.5.4/21, the first 21 bits are kept unchanged, while the rest are made into 0s.

IP address: 128.42.5.4

Netmask: 255.255.248.0

IP binary: 10000000 00101010 00000101 00000100

Netmask: 11111111 11111111 11111000 00000000

Logical AND: 10000000 00101010 00000000 00000000

i.e. network address: 128.42.0.0

Usage: cidr2network 128.42.5.4/21  # returns 128.42.0.0

cidr2broadcast()
----------------
The broadcast address converts all host bits to 1s, keeping the network part unchanged.

To calculate the broadcast address, we force all host bits to be 1s:

IP address: 128.42.5.4/21

IP binary: 10000000 00101010 00000101 00000100

Host mask: 00000000 00000000 00000hhh hhhhhhhh

Force host bits to 1s (keep network part unchanged): 10000000 00101010 00000111 11111111

i.e. broadcast address: 128.42.7.255

A broadcast address transmits to all devices connected to the network (hence all host bits should be 1).

Usage: cidr2broadcast 128.42.5.4/21  # returns 128.42.7.255

Subnetting
----------
Subnetting is the splitting of the host part of an IP address for internal use (to create multiple internal networks), while still acting like a single network to the outside world.
Example: the network 203.113.0.0/24 can be subnetted into 203.113.0.0/25 and 203.113.0.128/25.

Non-routable IP addresses
-------------------------
Non-routable addresses can be reused over and over internally (as leased by a router or DHCP server). These appear as private IP addresses.

Non-routable IP addresses     | Details
------------------------------|:-------------------------------
172.16.\*.\* - 172.31.\*.\*   | 172.16.0.0 - 172.31.255.255/12
192.168.\*.\*                 | 192.168.0.0 - 192.168.255.255/16
10.\*.\*.\*                   | 10.0.0.0 - 10.255.255.255/8
169.\*.\*.\*                  | self-assigned if no response from DHCP server
127.\*.\*.\*                  | loopback

IP header
---------
A packet carries several headers. The IP and TCP headers do not change along a packet's journey.

```
IP header
|
|--- Source IP address
|--- Destination IP address
|--- TTL (Time To Live)
|--- IP protocol version (4 or 6)
|--- Fragment offset
|--- Identification (the group ID which the packet belongs to)
|--- D|F (Don't Fragment)
|--- M|F (More Fragments; indicates that more packets are on the way; all packets except the last will have this bit)
|--- Type of service
|    |--- Priority (3 bits)
|    |--- Criterion (3 bits): indicates if host cares more about delay, throughput, or reliability
|--- Header checksum*
|--- ...  (IP header has more room for options, however such options are rarely used since many routers ignore them)
```

* IPv6 has no checksum. The argument against checksums is that any application that really cares about data integrity has to have a checksum in the transport layer, so having another one in the IP layer is overkill. Moreover, experience with IPv4 has shown that computing an IP checksum was a major expense, hence it was dropped in IPv6.
