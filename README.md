# RomBuilder

To use this script to build roms, include the repo in a buildkite build instance.

## Scripts

[setup-buildtools.sh](scripts/setup-buildtools.sh) - Install required build tools on the host

[start-local.sh](scripts/start-local.sh) - Start build within the buildkite environment using a specified config

[scripts/cloud](scripts/cloud) - Deploy buildkite and building tools to aws and gcloud

## Notes

See [README.md](docker) for specific build options and [https://github.com/robbalmbra/RomBuilder/wiki/Buildkite-Intergration](https://github.com/robbalmbra/RomBuilder/wiki/Buildkite-Intergration) for a buildkite setup guide.
