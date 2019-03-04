# Persistent Wordpress with autoprovisioning, & autoscaling K8's with Kubernetes, Terraform, and Helm for multiple environments/companies.
The example is Google Cloud but can easily be adapted for AWS or Azure

## Overview
- Prerequisities
- Terraform Kubernetes Cluster
- Install Helm
- Deploy Helm Charts for storage & wordpress
- Setup Pod Autoscaling

## Prerequisities
- A Google Cloud Account
- Installed gcloud CLI
- Create a new project or use an existing project_ID where you have Owner permissions.
  - Set the project_id: ```gcloud config set project your_project_id```



## Run Terraform
Setup and service account and run terraform

### Create an account for terraform apply permissions
Setup environment vars.
```
export TF_ADMIN=terraform-admin
export TF_CREDS=~/.config/gcloud/terraform-admin.json
```

Create a service account for terraform and download the json creds
```
$ gcloud iam service-accounts create terraform --display-name "Terraform admin account" 
$ gcloud iam service-accounts keys create ${TF_CREDS} \
  --iam-account terraform@${TF_ADMIN}.iam.gserviceaccount.com
```

Grant the service account permissions
```
$ gcloud projects add-iam-policy-binding ${TF_ADMIN} \
  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/viewer

$ gcloud projects add-iam-policy-binding ${TF_ADMIN} \
  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/storage.admin
```

Enable API's
```
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable cloudbilling.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable compute.googleapis.com
```

### Run Terraform

In the k8 directory, *edit k8.tf* and change the project in the provider block
```
$ terraform init
$ terraform plan
$ terraform apply
```

Get credentials for the clusters
```
$ gcloud container clusters get-credentials --region us-west2 k8wp
```

## Install helm
Install helm on your location workstation.  Here is an examle command for MAC
```
brew install kubernetes-helm
```
Go to the k8-helm-setup/ directory and run
```
$ kubectl apply -f create-helm-service-account.yaml
$ helm init --service-account helm
```

## Helm install persistent storage provisioner and wordpress

The following deploys a persistent nfs provisioner with 80 gb.  Each of the helm deploys for company-test1 and company-test2 sets up 2 and 1 replicas respectively and maria db with persistent volume claims against nfs storage class.
```
$ helm install stable/nfs-server-provisioner --set persistence.enabled=true,persistence.size=80Gi

$ helm install --name company-test1 -f company-test1.yaml --set persistence.storageClass=nfs stable/wordpress --set mariadb.master.persistence.storageClass=nfs

$ helm install --name company-test2 -f company-test2.yaml --set persistence.storageClass=nfs stable/wordpress --set mariadb.master.persistence.storageClass=nfs
```

Take note of the output on each command. There is additional information on how to obtain the connection URL and password you will need to login to the site and to Wordpress admin section.

> To create a 3rd company or environment.  Copy company-test1.yaml, edit, and install with helm install --name ... Look at one of the above lines for company-test1 or test2 for an example.

For Wordpress the default login is user and the password can be obtained using ```kubectl get secret --namespace default company-test1-wordpress -o jsonpath="{.data.wordpress-password}" | base64 --decode```

## Deploy metrics server and setup HPA (Optional)


### Custom and external metrics: 
Follow the instructions here https://medium.com/uptime-99/kubernetes-hpa-autoscaling-with-custom-and-external-metrics-da7f41ff7846 to install custom and external metrics servers.  Additional info can be found here https://cloud.google.com/kubernetes-engine/docs/tutorials/custom-metrics-autoscaling

An abbreviated version of the above:
```
$ kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole cluster-admin \
    --user "$(gcloud config get-value account)"

$ kubectl create -f https://raw.githubusercontent.com/GoogleCloudPlatform/k8s-stackdriver/master/custom-metrics-stackdriver-adapter/deploy/production/adapter.yaml
```

See the files **custom-metrics.txt** and **external-metrics.txt** for a list of available metrics.

To use a basic scaler on CPU or memory use the kubectl autoscale command:
```
kubectl autoscale rs company-test1-wordpress --min=2 --max=3 --cpu-percent=85
```

