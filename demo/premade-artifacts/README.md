Rtos artifacts were created with:

```bash
INTERFACE=rtos-interface
DEVICE=rtos
VERSION=$DEVICE-v3
PAYLOAD=$VERSION-payload

touch $PAYLOAD
mender-artifact \
  write module-image \
  --type $INTERFACE \
  --compatible-types $DEVICE \
  --file $PAYLOAD \
  --output-path $VERSION.mender \
  --artifact-name $VERSION
```



The manifest artifacts were created with:

``` bash
DEVICE_TYPE="qemux86-64"
./mender-orchestrator-manifest-gen \
    -n manifest-v1 \
    -o manifest-v1.mender \
    -t $DEVICE_TYPE \
    manifest-v1.yaml
```
