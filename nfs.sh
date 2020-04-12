# nfs-HA with drbd storage
echo "choise 1 to install pcs on all nodes."
echo "choise 2 to config pcs cluster only one node."
echo "choise 3 to config nfs-HA only one node."
read -p "pls input your choise [1]: " n

case $n in
1)
yum -y install pcs fence-agents-all lvm2-cluster 
systemctl enable pcsd
systemctl start pcsd
echo "liyang" | passwd --stdin hacluster
;;

2)
read -p "pls intput node1 hostname: " pcs1
read -p "pls intput node2 hostname: " pcs2
read -p "pls intput cluster name: " name
pcs cluster auth $pcs1 $pcs2 -u hacluster -p liyang
pcs cluster setup --name $name $pcs1 $pcs2
pcs cluster start --all
pcs cluster enable --all
pcs property set stonith-enabled=false
pcs status cluster
;;

3)

read -p "pls input nfs vip [192.168.20.174]: " vip
read -p "pls input drbd device [drbd0]: " drbd

pcs property set stonith-enabled=false

pcs resource create FsXFS Filesystem device="/dev/$drbd" directory="/nssdata" fstype="xfs" options="discard,rw,noatime,allocsize=1g,nobarrier,inode64,logbsize=262144,wsync" op monitor interval=40s on-fail=fence OCF_CHECK_LEVEL=20 --group nfsgroup

pcs resource create NFSDaemon nfsserver nfs_shared_infodir=/nssdata/nfsinfo nfsd_args=" 256 " nfs_no_notify=true op monitor timeout=60s interval=30s --group nfsgroup

pcs resource create NFSExport exportfs clientspec="*" options="rw,sync,no_root_squash,no_subtree_check,insecure" directory="/nssdata" fsid="55" --group nfsgroup

pcs resource create vip IPaddr2 ip=$vip cidr_netmask=24 op monitor interval=20s OCF_CHECK_LEVEL=10 on-fail=fence --group nfsgroup

pcs resource create NFSnotify nfsnotify source_host=$vip --group nfsgroup
;;

*)
echo "pls input 1-3 choise."
exit;

esac
