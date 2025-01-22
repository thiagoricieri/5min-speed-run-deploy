## 5min _Speed Run_ Deploy

This is a simple setup and deploy scripts to run a server with Nginx, Node and SSL enabled.

### Must-Haves

1. Have your code in a GitHub repository
2. Have a server running somewhere (I use Digital Ocean)
3. Have a domain with `A` record pointing to your server IP

### Getting Started

1. Copy the script to your box using:

```shell
scp box/speed_run_deploy.sh root@server_ip:~/speed_run_deploy.sh
```

2. Log into your server

```shell
ssh root@server_ip
```

> Obs: Assuming you're logging in as `root`, the script will create a deployer user.

3. Run the script and follow the instructions!

```shell
bash speed_run_deploy.sh
```

It will install Nginx, PM2, Node.js, setup SSL and Firewall for you.

### After Setup...

4. Exit the box
5. (From your machine) Copy the public key (it was created in ~/.ssh/deployer.pub in your machine):

```shell
cat ~/.ssh/deployer.pub | pbcopy
```

6. Go to https://github.com/settings/keys
7. Click 'Add new SSH' Key and paste the contents in public key field
8. Copy the private key contents (it was created in ~/.ssh/deployer in your machine):

```shell
cat ~/.ssh/deployer | pbcopy
```

9. Push your code to Github

10. Copy the repository URL

11. Go to `https://github.com/<YOUR GITHUB USER>/<YOUR REPO NAME>/settings/secrets/actions`

12. Create secret `SSH_PRIVATE_KEY` and paste the private key contents

13. Create secret: `SERVER_IP` as <YOUR SERVER IP>

14. Create secret: `SERVER_USER` as <YOUR SERVER USER>

15. SSH into your server using the deployer user:

```shell
ssh -i ~/.ssh/deployer deployer@<YOUR SERVER IP>
```

16. Clone your repository into `/var/www/<DOMAIN NAME>`

```shell
git clone https://github.com/<YOUR GITHUB USER>/<YOUR REPO NAME>.git /var/www/<DOMAIN NAME>
```

Done! Every merge to main branch will be deployed.

### Try it out!

17. Commit something to the `main` branch (or the one you selected in setup)
18. The action will run automatically, wait until it finishes
19. Access your domain and there you have it!

## Boilerplate

### Use the template for a Next.js application...

This is a [Next.js](https://nextjs.org/) project bootstrapped with [create-next-app](https://github.com/vercel/next.js/tree/canary/packages/create-next-app). You may use the boilerplate as is, it works!

### ...or use it for another stack!

You just need the following files if you want just the deploy script:

```
.github/actions/deploy.yaml
.github/workflows/deploy-prod.yaml
box/speed_run_deploy.sh
```

You will also need to edit `speed_run_deploy.sh` because it creates a `deploy.sh` script that you may want to edit.

Cheers,

**Thiago V Ricieri**

- System Thinker @ [Systematic Success](https://systematicsuccess.net/?utm_source=github&utm_medium=social&utm_campaign=speed_run_deploy)
- Maker @ [Making of a Maker](https://makingofamaker.substack.com/?utm_source=github&utm_medium=social&utm_campaign=speed_run_deploy)
- Engineering Manager,  Apps @ [Pluto TV](https://pluto.tv/) / [Paramount Global](https://paramount.com/)
- Founder @ [Ghost Ship & Co.](https://ghostship.co/?utm_source=github&utm_medium=social&utm_campaign=speed_run_deploy)
- Digital Nomad @ [Threads](https://www.threads.net/@thgvr), [X.com](http://x.com), [LinkedIn](https://linkedin.com/in/thiagoricieri), [GitHub](https://github.com/thiagoricieri), [Instagram](https://www.instagram.com/thgvr), [Website](https://thgvr.com/?utm_source=github&utm_medium=social&utm_campaign=speed_run_deploy)
