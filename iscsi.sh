# dual primary role with pcs
read -p "pls input drbd device [drbd0]: " drbd
pcs cluster cib drbd_cfg
pcs -f drbd_cfg resource create data ocf:linbit:drbd drbd_resource=$drbd op monitor interval=60s
pcs -f drbd_cfg resource master dataClone data master-max=2 master-node-max=1 clone-max=2 clone-node-max=1 notify=true
pcs -f drbd_cfg resource show
pcs cluster cib-push drbd_cfg

# iscsi-target with pcs
read -p "pls input iscsi vip [192.168.20.174]: " vip
read -p "pls input iscsi device [drbd0]: " dev
pcs resource create vip IPaddr2 ip=$vip cidr_netmask=24 op monitor interval=20s OCF_CHECK_LEVEL=10 on-fail=fence --group iscsigroup

pcs resource create target1 iSCSITarget \
portals=$vip iqn="iqn.2020-04.com.storage:ceph" implementation="lio-t" \
allowed_initiators="iqn.1994-05.com.redhat:c06" --group iscsigroup

pcs resource create lun1 iSCSILogicalUnit \
target_iqn="iqn.2020-04.com.storage:ceph" \
lun="1" path="/dev/$dev" --group iscsigroup

# update allowed-initiators
pcs resource update target1 iSCSITarget \
allowed_initiators="iqn.1998-01.com.vmware:c01 iqn.1998-01.com.vmware:c02"
