
To be able to deploy this local infrastructure you need to have installed `Virtualbox`. You can install it from [here](https://www.virtualbox.org/). 

This folder includes a `Vagrantfile` that will launch two Ubuntu instances on your workstation. Note the instances will mount the local `./data` folder in the directory where you launch `vagrant up` into both instances under `/data`. This is what we will use to simulate shared storage across these two VMs.

---
**NOTE**

you need to manually create the `./data` folder before launching `vagrant up`.  

---

If you want to launch those virtual machines other than on your workstation, take a look at the [Vagrant documentation](https://www.vagrantup.com/docs/providers) to explore its `Providers`. You need to make sure they all see a shared folder on the `/data` mount point.  

You can gain a shell into these VMs using either `vagrant ssh ecs-anywhere-1` or `vagrant ssh ecs-anywhere-2`. 

Congratulations, you can now move to the next steps in the tutorial.
