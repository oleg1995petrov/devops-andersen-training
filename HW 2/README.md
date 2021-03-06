# Homework overview

1. Need to create and deploy to Debian 10 virtual machine (hereinafter VM) service
   is written in [Flask][flask] via Ansible playbook: 
    * The service listens at least on port 80 (443 as an option). 
    * The service accepts GET & POST methods.
    * The service should receive `JSON` object and return strings in the following manner:
       
      ```bash
      # request
      curl -XPOST -d '{"animal": "cow", "sound": "mooo", "count": 3}' myvm.localhost

      # repsonse
      cow says mooo
      cow says mooo
      cow says mooo
      Made with     by %my_name

      # request
      curl -XPOST -d '{"animal": "elephant", "sound": "whoooaaa", "count": 5}' myvm.localhost

      # repsonse
      elephant says whoooaaa
      elephant says whoooaaa
      elephant says whoooaaa
      elephant says whoooaaa
      elephant says whoooaaa
      Made with     by %my_name    
      ```

2. Configure `systemd` so that the app starts after a reboot.
3. Secure the VM so that the app is not stolen:
    
    * allow connections only to the ports 22, 80, 443.
    * disable root login, all authentication except 'public keys'.

## Requirements

  * Ansible
  * VirtualBox VM with Debian 10
    
## The User Guide

1. If you use a server image of Debian 10 go to the 3rd step.
   For a desktop image you have to install into VM `openssl-server`:

    ```bash
     sudo apt install -y openssl-server
     ```  

2. Set up `sshd_config` on VM by editing `/etc/ssh/sshd_config` file.
   Uncomment the next lines and set the next values:
    
    * `Port 22`
    * `HostKey /etc/ssh/ssh_host_rsa_key`
    * `AuthorizedKeysFile .ssh/authorized_keys`
    * `PubkeyAuthentication yes`
    * `PasswordAuthentication yes`

    After that reload the ssh service:

    ```bash 
    sudo service ssh reload
    ```

3. Copy your **pub** RSA key from local machine to remote: 

    ```bash 
    ssh-copy-id -i [/path/2/key (usually locates at /home/[your username]/.ssh/)] [VM's username]@[VM's ip address]
    ```
   
    If you have no RSA keys yet, first install a couple:

    ```bash
    ssh-keygen -t rsa -f /home/[your username]/.ssh/id_rsa
    ```

    After that copy your **pub** key as was written above.

4. Set up the playbook. Edit `roles/common/vars/main.yml` file
   and set the next variables:
    
    * **project_name:** [a desirable name of project]
    * **ansible_user:** [VM's username]

5. Put the VM's IP address in the **inventory** file.

6. Create an encrypted file with VM's account password:

    ```bash
    ansible-vault create [password_file_name.yml (e.g.: passwd.yml)]
    ```

    Enter a password to protect that file. Inside it put the `ansible_become_pass`
    variable with VM's account password:

    ```bash
    ansible_become_pass: [your VM's account password]
    ```

7. Install the required ansible module:  
    
    ```bash
    ansible-galaxy collection install community.crypto
    ```

8. Start the playbook. At the homework root directory execute:

    ```bash
    ansible-playbook -i inventory -e @passwd.yml --ask-vault-pass deploy.yml
    ```

    Enter the password of your encrypted file and wait while Ansible
    will execute the playbook. It may take a few minutes.
   
    ! Note that if you use `curl` with `HTTPS` protocol you have to use `-k` argument
    to allow `curl` to proceed and operate with self-signed SSL certificate. 

[flask]: https://github.com/pallets/flask
