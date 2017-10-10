This pipeline is for collecting the stemcells required when doing an upgrade of Pivotal Cloud Foundry Operations Manager when the Ops Manager VM is in an offline/disconnected environment.

The normal upgrade-ops-manager workflow includes exporting diagnostic information and configuration from the existing Ops Manager VM, standing up the new Ops Manager VM, importing the configuration from the old VM, and then using the diagnostic information to download stemcells from Pivotal Network and then upload them to the new Ops Manager VM.

When upgrading Ops Mananager in an offline environment those stemcells must be provided somehow; this pipeline help achieve that.

This pipeline expects the [diagnostic report](http://opsman-dev-api-docs.cfapps.io/#diagnostic-report) to be placed in an S3 bucket under the path "<bucket>/diagnostic_reports" with a filename like `diagnostic_report_v<version>.json`, where version is a monotonically increasing number or a semver-compatible number, e.g. `diagnostic_report_v1.2.3.json`.

It then uses that information to figure out what matching stemcells already exist in the configured S3 bucket at the path "<bucket>/stemcells/", and for each missing stemcell copies it from Pivotal Network to "<bucket>/stemcells/". It has another job for creating a single tarball of all the required stemcells for that particular report, and it re-uses the report's version for the tarball's own version so they can be tracked more easily.

This tarball can then be copied to offline media for use in transporting to the destination, where its contents can be copied into the necessary locations within S3.

Suggestions for improvement:
* The tarball should contain a SHA sum of the contents for verification within the offline environment
* The tarball should be encrypted to ensure the contents are not tampered with during transit
* There could be another pipeline made that does the export of the diagnostic report to S3 using a semver resource for tracking the version
* There could be another pipeline made that looks at a particular bucket for the (possibly encrypted) tarball containing the stemcells, and is in charge of decrypting the tarball, verifying the SHA sum, and copying each stemcell to the appropriate place in the offline S3 blobstore
