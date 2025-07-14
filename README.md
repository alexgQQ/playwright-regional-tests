
# Regional Testing with Playwright and GCP

This repo is for running playwright tests against a web application in a multi regional context using GCP. The goal here specifically is to test that our image sources load expecting when accessing the application from various regions. It serves as a bit of an example of how you could execute some form of validation across different geographical areas. The overall process is to build vm instances with the dependencies for playwright and the tests ready to go and then to deploy them across multiple zones to run the tests and then aggregate the results in GCP bucket. These are meant to be ran manually and not in a CI context.

## Dependency Setup

This uses GCP for their compute instances. So make sure to have the gcloud cli installed and authenticated.
https://cloud.google.com/docs/authentication/provide-credentials-adc

This also required terraform. I recommend using [tfswitch](https://tfswitch.warrensbox.com/Installation/).

This also requires node 22+ along with npm and npx. I recommend using [nvm](https://github.com/nvm-sh/nvm)

## Build the Base Image

First we need to build a base image for with our required dependencies. This saves us some compute time for each test instance.

```bash
gcloud compute instances create playwright-image-builder \
  --project=$GCP_PROJECT \
  --zone=$GCP_ZONE \
  --machine-type=e2-medium \
  --metadata-from-file=startup-script=install_deps.sh
```

Give it a few minutes and check back on the instance status. It should be shutdown and ready for creating the image.
Make the image from the vm in the us region.
TODO: To use the image globally we also need to make the image for eu and asia regions. This cannot be done for a single image so a separate image must be made for each of these regions.

```bash
gcloud compute images create playwright-image \
  --source-disk=playwright-image-builder \
  --source-disk-zone=$GCP_ZONE \
  --storage-location=us
```

If the instance is not shutdown then something likely went wrong. Ssh into the instance and checkout the startup service.

```bash
gcloud compute ssh playwright-image-builder
# in instance
sudo journalctl -u google-startup-scripts.service
```

## Running the Tests

With the base image ready we can deploy the test instance. Check out the `variables.tf` file and update them as needed. 
Mostly you'll need to update the instance zones that we'll want to deploy in and the name of the compute image made above.
Add a `terraform.tfvars` file with the `project` and `bucket_path` variables.

```bash
cd terraform

# first time setup
terraform init

terraform plan
terraform apply
```

Give it a few minutes and the instances should be complete. Download and merge the reports to view the results.

```bash
cd ../playwright
gsutil -m cp gs://bucket/path/to/reports/* ./blob-reports
npx playwright merge-reports --reporter html ./blob-report
npx playwright show-report
```

Or view the results from a specific region.

```bash
cd ../playwright
gsutil -m cp gs://bucket/path/to/reports/report-us-central1-a.zip ./blob-reports
npx playwright merge-reports --reporter html ./blob-report
npx playwright show-report
```

## Debugging

If something is wrong with the tests they can be ran locally. Just `npx playwright test` and work through whatever issue may be there.
On deployment you'll need to check some logs. The startup process service that runs the scripts is `google-startup-scripts.service` so tail those for more information.
On the test runners themselves the logs will include the logs from the image building process so tail the end. You may also need to deploy them again but comment out the `shutdown` command so they don't automatically shutdown on startup.
