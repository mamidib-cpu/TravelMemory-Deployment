# TravelMemory – MERN Deployment on AWS EC2

Deployment of the TravelMemory MERN app (React frontend, Node/Express backend, MongoDB) on AWS EC2 with Nginx, Application Load Balancers and a Cloudflare custom domain.

Source app: https://github.com/UnpredictablePrashant/TravelMemory

> Replace `yourdomain.com`, IPs, ALB DNS names and the Mongo URI with your own values. Add a screenshot at every step marked 📸.

## 1. Architecture

See `architecture.drawio` (open at https://app.diagrams.net).

```
User -> Cloudflare DNS
          |-- A     yourdomain.com      -> Frontend EC2 public IP
          |-- CNAME api.yourdomain.com  -> Backend ALB DNS name
Frontend ALB -> Frontend EC2 #1, #2 (Nginx serving React build)
Backend  ALB -> Backend  EC2 #1, #2 (Nginx :80 -> Node :3000 via PM2)
Backend EC2s -> MongoDB Atlas
```

## 2. Prerequisites
- AWS account, Cloudflare account, a registered domain
- MongoDB Atlas free cluster (create DB user, copy the connection string)
- An EC2 key pair (`.pem`)

## 3. Network and security (best practice)
1. Create security groups (📸):
   - `alb-sg`: inbound 80 (and 443 if using HTTPS) from `0.0.0.0/0`
   - `ec2-sg`: inbound 80 **from `alb-sg` only**; inbound 22 **from your IP only**
2. In Atlas → Network Access, allow the backend EC2 public IPs (or NAT IP) rather than `0.0.0.0/0`.
3. Never commit `.env`; it is created on the server with `chmod 600`.

## 4. Backend EC2 (Task 1)
1. Launch EC2: Ubuntu 22.04, t2.micro/t3.micro, `ec2-sg`, your key pair (📸).
2. SSH in: `ssh -i key.pem ubuntu@<backend-ip>`
3. Copy `setup-backend.sh` and `nginx-backend.conf` to the home directory, then:
   ```bash
   bash setup-backend.sh "mongodb+srv://<user>:<pass>@<cluster>/travelmemory"
   ```
   The script installs Node 20, Nginx and PM2, clones the repo, writes `backend/.env` (`MONGO_URI`, `PORT=3000`), starts the app with PM2 (restart on reboot) and configures Nginx as a reverse proxy to `127.0.0.1:3000` (📸).
4. Verify: `curl http://localhost/hello` returns a response; `pm2 status` shows `online` (📸).

Check the variable name in `backend/index.js` / `.env` (the repo uses `MONGO_URI` and `PORT`); adjust if your copy differs.

## 5. Frontend EC2 (Task 2)
1. Launch another EC2 as above (📸).
2. Copy `setup-frontend.sh` and `nginx-frontend.conf`, then:
   ```bash
   bash setup-frontend.sh "http://api.yourdomain.com"
   ```
   It edits the frontend URL file (`frontend/src/url.js` in the repo; the assignment calls it `urls.js`) so `baseUrl` points at the backend, builds React (`npm run build`) and serves `build/` from Nginx (📸).
3. Browse to `http://<frontend-ip>` and confirm the app loads and can add/view trips (📸).

## 6. Scaling with load balancers (Task 3)
1. Create an AMI from each configured instance (EC2 → Actions → Image) (📸), then launch a second backend and a second frontend from those AMIs.
2. Create two target groups (HTTP:80, health check path `/health`): `tm-frontend-tg`, `tm-backend-tg`. Register the matching instances (📸).
3. Create two Application Load Balancers (internet-facing, `alb-sg`): `tm-frontend-alb` → `tm-frontend-tg`, `tm-backend-alb` → `tm-backend-tg` (📸).
4. Wait until targets show **healthy**; test by opening each ALB DNS name (📸).
5. Stop one instance and confirm the app still works (resilience test) (📸).

## 7. Cloudflare domain (Task 4)
1. Add your domain to Cloudflare and switch the registrar nameservers to Cloudflare's (📸).
2. Add DNS records (📸):
   | Type  | Name  | Target                              | Proxy |
   |-------|-------|-------------------------------------|-------|
   | A     | `@`   | Frontend EC2 public (Elastic) IP    | on    |
   | CNAME | `api` | Backend ALB DNS name                | on    |
   Use an Elastic IP for the A record so it does not change on restart.
3. Set `baseUrl` in the frontend to `http://api.yourdomain.com` (or `https://` once SSL is on), rebuild and redeploy the frontend.
4. SSL: in Cloudflare set SSL/TLS to **Flexible** (or Full with an origin cert/ACM on the ALB for end-to-end HTTPS).
5. Verify `https://yourdomain.com` loads and talks to the backend (📸).

## 8. Verification checklist
- [ ] `https://yourdomain.com` loads the React app
- [ ] Creating/listing a trip works (data in Atlas)
- [ ] Both ALB target groups healthy
- [ ] App survives stopping one instance
- [ ] SSH only from your IP; EC2s reachable on 80 only from ALB

## 9. Troubleshooting
- **502 from Nginx**: `pm2 logs`, confirm Node on 3000 and MONGO_URI valid.
- **CORS / mixed content**: use the same scheme (https) for site and API URL.
- **Mongo connection timeout**: add EC2 IP to Atlas Network Access.
- **Unhealthy targets**: check `/health` and that `ec2-sg` allows 80 from `alb-sg`.

## 10. Repository contents
- `README.md` – this guide
- `architecture.drawio` – architecture diagram
- `nginx-backend.conf`, `nginx-frontend.conf` – Nginx configs
- `setup-backend.sh`, `setup-frontend.sh` – automated setup scripts
- `screenshots/` – your step screenshots
