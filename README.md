# BOSH Errand Resource

An output only resource (at the moment) that will run errands.

Forked from Bosh Deployment Resources, Thanks Chris Brown and Alex Suraci

## Source Configuration

* `target`: *Optional.* The address of the BOSH director which will be used for
  the deployment. If omitted, `target_file` must be specified via `out`
  parameters, as documented below.
* `username`: *Required.* The username for the BOSH director.
* `password`: *Required.* The password for the BOSH director.
* `deployment`: *Required.* The name of the deployment.

### Example

``` yaml
- name: staging
  type: bosh-errand
  source:
    target: https://bosh.example.com:25555
    username: admin
    password: admin
    deployment: staging-deployment-name
```

``` yaml
- put: staging
  params:
    manifest: path/to/manifest.yml
    errand: smoke-tests
```

## Behaviour

### `out`: Deploy a BOSH deployment

This will upload any given stemcells and releases, lock them down in the
deployment manifest and then deploy.

If the manifest does not specify a `director_uuid`, it will be filled in with
the UUID returned by the targeted director.

#### Parameters

* `manifest`: *Required.* Path to a BOSH deployment manifest file.

* `errand`: *Required.* Name of errand to be ran.

* `target_file`: *Optional.* Path to a file containing a BOSH director address.
  This allows the target to be determined at runtime, e.g. by acquiring a BOSH
  lite instance using the [Pool
  resource](https://github.com/concourse/pool-resource).

  If both `target_file` and `target` are specified, `target_file` takes
  precedence.
