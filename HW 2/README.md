# Homework 2 overview

1. Need to create and deploy to virtual machine (hereinafter VM) service is written in [Flask][flask] via Ansible playbook. 
    * The service listens at least on port 80 (443 as an option). 
    * The service accepts GET & POST methods.
    * The service should receive `json` object and return strings in the following manner:
        
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

2. Configure `systemd` so that the app starts after reboot.
3. Secure the VM so that app is not stole:
    * allow connections only to the ports 22, 80, 443.
    * disable root login, all authentication except 'public keys'.

## Requirements
    * Debian 10
    * VirtualBox VM
___
    
## Solution

1. If you use a server image of Debian 10 go to the 3rd step.

    Into VM install `openssl-server`:

   ```bash
   $ sudo apt install -y openssl-server
   ```  

2. Set up `sshd_config` on VM by editing `/etc/ssh/sshd_config` file. Uncomment the next lines and set the next values:
    * `Port 22`
    * `HostKey /etc/ssh/ssh_host_rsa_key`
    * `AuthorizedKeysFile .ssh/authorized_keys`
    * `PubkeyAuthentication yes`
    * `PasswordAuthentication yes`

    After that reload the ssh service:

   ```bash 
   $ sudo service ssh reload
   ```

3. Copy your pub rsa key from local machine to remote: 

   ```bash 
   $ ssh-copy-id -i [/path/2/your/pub/key (usually locates at /home/[your username]/.ssh/id_rsa.pub or other name)] [your VM's username]@[VM's ip address]
   ```  
   
   If you have no rsa-keys yet, first install a cuple:

   ```bash
   $ ssh-keygen -t rsa -f /home/[your username]/.ssh/id_rsa 
   ```  
   
   After that copy your pub key as was written above.

3. Set up the playbook. Edit `roles/common/vars/main.yml` file and set the next variables:
    * **project_name:** [a desirable name of your project]
    * **ansible_user:** [your VM's username]

4. Put your VM's ip address to **inventory** file.

5. Create an encrypted file with your VM's account password:

   ```bash
   $ ansible-vault create [password_file_name e.g.: passwd.yml]
   ```  
   
   Enter a password to protect that file. Inside it put `ansible_become_pass` variable with your VM's account password:

   ```bash
      $ ansible_become_pass: [your VM's account password]
   ```

6. And now start the playbook

    At the root directory:

   ```bash
   $ ansible-playbook -i inventory -e @passwd.yml --ask-vault-pas deploy.yml
   ```
   
   Enter the password of your password file and wait while Ansible will execute playbook. It may take a few minutes.





[flask]: https://github.com/pallets/flask
