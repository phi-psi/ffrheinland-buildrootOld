cloud_is_online () {
    # look for mac addrs in batman gateway list
    batctl gwl | tail -n-1 | egrep -q '([0-9a-f]{2}:){5}[0-9a-f]{2}'
}

## add/remove IPv4/IPv6 address from mesh iface
# manual update to avoid full ifdown+ifup, but update uci state for
# other users (e.g. dnsmasq)
mesh_add_ipv4 () {
    ifconfig br-mesh $1 netmask $2
    echo "
set network.mesh.ipaddr=$1
set network.mesh.proto=static
set network.mesh.netmask=$2
" | uci batch
}

mesh_del_ipv4 () {
    ifconfig br-mesh 0.0.0.0
    echo "
delete network.mesh.ipaddr
delete network.mesh.proto
delete network.mesh.netmask
" | uci batch
}

mesh_add_ipv6 () {
    ifconfig br-mesh add $1
    echo "
set network.mesh.ip6addr=$1
" | uci batch
}

mesh_del_ipv6() {
    ifconfig br-mesh del $1
    echo "
delete network.mesh.ip6addr
" | uci batch
}

# enable/disable uhttpd instance in uci config; the parameters are
# 1. instance name
# 2. addresses to listen on (white-space delimted list)
enable_httpd () {
    uci set uhttpd.$1=uhttpd
    for i in $2; do
	uci add_list uhttpd.$1.listen_http=$i
    done
}

disable_httpd () {
    uci set uhttpd.$1=disabled
    uci delete uhttp.$1.listen_http &>/dev/null || true
}

# change the interfaces the service httpd is listening on;
# automatically adds linklocal IPv6 addresses of br-mesh and br-lan
change_service_httpd_listen () {
    uci delete uhttp.service.listen_http &>/dev/null || true
    for i in $1 \
	[$(ifconfig br-mesh | egrep -o 'fe80[:0-9a-f]*')%br-mesh]:80 \
	[$(ifconfig br-lan  | egrep -o 'fe80[:0-9a-f]*')%br-lan]:80; do
	uci add_list uhttpd.service.listen_http=$i
    done
}
