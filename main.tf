/*
This is a test server definition for GCE+Terraform for GH-9564
*/

provider "google" {
  project                     = var.project
  region                      = var.region
  impersonate_service_account = "sa-terraform@shareddevops01.iam.gserviceaccount.com"
}

resource "google_compute_firewall" "firewall" {
  name    = "gritfy-firewall-externalssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"] # Not So Secure. Limit the Source Range
  target_tags   = ["externalssh"]
}

resource "google_compute_firewall" "webserverrule" {
  name    = "un-webserver"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"] # Not So Secure. Limit the Source Range
  target_tags   = ["nithin"]
}

# # We create a public IP address for our google compute instance to utilize
resource "google_compute_address" "static" {
  name       = "vm-public-address"
  project    = var.project
  region     = var.region
  depends_on = [google_compute_firewall.firewall]
}


resource "google_compute_instance" "dev" {
  name         = "un-test"         # name of the server
  machine_type = "f1-micro"        # machine type refer google machine types
  zone         = "${var.region}-b" # `a` zone of the selected region in our case us-central-1a
  tags         = ["nithin"] # selecting the vm instances with tags

  # to create a startup disk with an Image/ISO. 
  # here we are choosing the CentOS7 image
  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
      # auto_delete = true
      # boot = true
      # disk_encryption_key{
      # } 
    }
    kms_key_self_link = var.cmek_crypto_key
  }

  # We can create our own network or use the default one like we did here
  network_interface {
    # network    = "default"
    subnetwork = google_compute_subnetwork.test-subnet-1.name
    # assigning the reserved public IP to this instance
    # access_config {
    #  subnetwork = "${google_compute_subnetwork.test-subnet-1.name}"
    # }
  }

  # This is copy the the SSH public Key to enable the SSH Key based authentication
  metadata = {
    ssh-keys = "${var.user}:${file(var.publickeypath)}"
  }

  # to connect to the instance after the creation and execute few commands for provisioning
  # here you can execute a custom Shell script or Ansible playbook
  # provisioner "remote-exec" {
  #   connection {
  #     host = google_compute_address.static.address
  #     type = "ssh"
  #     # username of the instance would vary for each account refer the OS Login in GCP documentation
  #     user    = var.user
  #     timeout = "500s"
  #     # private_key being used to connect to the VM. ( the public key was copied earlier using metadata )
  #     private_key = file(var.privatekeypath)
  #   }

  #   # Commands to be executed as the instance gets ready.
  #   # installing nginx
  #   inline = [
  #     "sudo yum -y install epel-release",
  #     "sudo yum -y install nginx",
  #     "sudo nginx -v",  
  #   ]
  # }

  # Ensure firewall rule is provisioned before server, so that SSH doesn't fail.
  # depends_on = [google_compute_firewall.firewall, google_compute_firewall.webserverrule]

  # Defining what service account should be used for creating the VM
  service_account {
    email  = var.email
    scopes = ["compute-ro"]
  }
}

resource "google_compute_network" "default" {
  name                    = "paddy-test-12747"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "test-subnet-1" {
  name          = "test-subnet-1"
  ip_cidr_range = "10.2.0.0/24"
  network       = google_compute_network.default.self_link
  region        = "us-central1"
}
