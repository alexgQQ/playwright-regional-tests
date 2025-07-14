## Build the Base Image

First we need to build a base image for with our required dependencies. This saves us some compute time for each test instance.

```bash
gcloud compute instances create playwright-image-builder \
  --project=$GCP_PROJECT \
  --zone=$GCP_ZONE \
  --machine-type=e2-medium \
  --metadata-from-file=startup-script=install_deps.sh
```

Give it a few minutes and check back on the instance status. It will be shutdown if successful. Then make the images.
We cannot make the images themselves fully global so we'll have to make an image per major global region (us, eu, asia).

```bash
gcloud compute images create playwright-image-us \
  --source-disk=playwright-image-builder \
  --source-disk-zone=$GCP_ZONE \
  --storage-location=us
```

If the instance is not shutdown then something likely went wrong. Ssh into the instance and checkout the startup service.

```bash
gcloud compute ssh playwright-image-builder
...
sudo journalctl -u google-startup-scripts.service
```
