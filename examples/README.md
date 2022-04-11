# Mixer examples: mixing C and assembler #

These examples need an installed VASM, VLINK and VBCC. The environment
variables `NDK39_INCLUDE`, `NDK39_ASMINCLUDE`, `VBCC`, and `T7D` must
be set.

Using the vbcc Docker image the following line in the root directory
of the repository will build the examples. Remember that the
compilation has to be started in the root of the repository as
symlinks are used and they must be visible to the running container.

```
docker run -e T7D=/opt/t7d -u 1000:uucp -v "$PWD/framework":/opt/t7d -v "$PWD":/host -w /host --rm  vintagecomputingcarinthia/vbcc4vcc make -C mixer
```
