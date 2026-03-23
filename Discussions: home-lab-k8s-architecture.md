Discussions: home-lab k8s architecture
contenxt: "Layer 3: Modern Routing (Envoy Gateway)
Instead of giving every app its own IP (which wastes IPs), we use a Gateway.

Your Setup: Envoy Gateway gets one IP from MetalLB (101.101.0.132).
The Magic: It acts like a receptionist. It looks at the Domain Name you typed (grafana.homelab.local) and forwards you to the correct internal service.
doubt:
    1 : if i want to set a static ip how will i go for it ?
    2 :  can i buy tdifferent domain and ppint it to the static ip and use it for the services ?
    3 :  do i nned to write the different routing route right it in the envoy gateway ?
    

Idea to learn
    1 :  what is i have no static ip i want to use the public ip from the is p provider get that and acess through it 
         Ans: Use Dynamic DNS (DDNS) like DuckDNS or Cloudflare DDNS. A script updates your domain whenever your ISP changes your IP.
    2 :   first to get it we need sopke helo punching i gues without that its not possible right ?
         Ans: If you have a direct Public IP (even if dynamic), Port Forwarding works. If you are behind CGNAT, you need "Hole Punching" or Tunnels (Cloudflare Tunnels, Tailscale).
    3 :    hole punching an thingking we can createan AI agent in the sytem may be penclaw is designed for this i doint know. that agent reads our whatsap message or email or any message and based on that it will do the changes in the cluster.  or it can hole puch and get teh publicc ip and use that for the public acess
         Ans: This is possible using LLM agents (LangChain/CrewAI) with tools to execute `kubectl` or `wireguard` commands.

doubt: even if you say DHCP ips its kind of static only once router reboots or once in week only it chnages practicaly they are gving every router a static ip only right ? 
    Ans: They are "Sticky," but not guaranteed. A power outage or ISP maintenance can change it instantly, locking you out if you don't have DDNS as a backup.

doubt: what DDNS is and how oit helps us ?
    Ans: Dynamic DNS (DDNS) is a service that automatically updates your Domain Name records when your ISP changes your Public IP. It acts like a "permanent name" for a "changing address," ensuring your homelab is always reachable via a URL like `my-k8s.duckdns.org`.

doubt: what if the router is behind CGNAT?
    Ans: In CGNAT, DDNS alone is **useless** for inbound traffic because you share a public IP with many others. You cannot use Port Forwarding. Instead, you MUST use an **Outbound Tunnel** (like Cloudflare Tunnels). The tunnel connects from your cluster **out** to the internet, creating a bridge that traffic can flow back through.

doubt: why i can also use any opensource library for holepunching right?
    Ans: Yes! You can use **WireGuard** (DIY Tunnel), **Headscale** (Open source Tailscale), or **WebRTC libraries (aiortc)** for programmatic hole punching inside an AI agent.

doubt: what is CGNAT ?
    Ans: Carrier Grade NAT (CGNAT) is when your ISP shares one Public IP address among hundreds of households. Because you don't "own" the public IP at your router, standard Port Forwarding won't work. You must use Tunnels (like Cloudflare) to "punch" through from the inside.

doubt: It uses STUN/TURN (Session Traversal Utilities for NAT) to negotiate a path between your phone and your home cluster, even through multiple NAT layers. but turn and stun need a pulic acess server right ?
    Ans: Yes, exactly! STUN/TURN servers must have a Public IP to act as the "meeting point" for your devices. This is why services like Tailscale provide these servers for you (called DERP servers), or you can host your own (like `coturn`) on a cheap VPS.

doubt:  so you are saying hole punching wont work everytime ?
    Ans: Correct. Hole punching (STUN) fails when you have a **Symmetric NAT** (common in large corporate networks and some 4G/5G providers). In Symmetric NAT, the router changes the external port for every different destination you talk to, making it impossible for the other side to "guess" which port to use.

doubt: if we are on a symmetric NAT then also cloudflared will work?
    Ans: **Yes!** Cloudflare Tunnels work by establishing an *outbound* connection to Cloudflare's edge. Because it is a client-server connection (not Peer-to-Peer), Symmetric NAT treats it as normal outbound web traffic and allows it. This is why Tunnels are the most reliable way to bypass restrictive home/office networks.

doubt: Is Cloudflare Tunnels free or headscale also installed on a public server right?
    Ans: Cloudflare Tunnels are **free** for personal use. **Headscale** (or Tailscale) DOES require a public coordination server (a "Discovery" point) so that your nodes can find each other from different networks.

doubt: does it mean tunnels and turn servers are same?
    Ans: No. **TURN** is a relay for Peer-to-Peer traffic (packets don't change, it just bounces them). A **Tunnel** is a permanent proxy bridge allowed to expose internal websites (HTTP) to the public web, often handling SSL and security rules on top.

doubt: that means a dedicated system running for you in public IP and that is connected to your homelab right? so a client will connect to that server and keep the connection with that server?
    Ans: **Exactly.** A Public "Bridge" (Cloudflare's Edge or your own VPS) acts as the meeting point. Your homelab reaches OUT to this bridge initially. When you (the client) connect to that public bridge, it simply relays the traffic back and forth through that pre-established "pipe." This is how you bypass all NAT and ISP restrictions.

doubt: Linkerd as service mesh, what are the alternatives and why choose Linkerd?
    Ans: 
    - **Istio:** The "Industrial" choice. Very powerful but very heavy (high RAM/CPU usage) and complex.
    - **Cilium:** Next-gen eBPF-based mesh. Fast and sidecar-less, but requires specific networking setups.
    - **Linkerd:** The "Homelab King." It is ultralight (Rust-based), extremely simple to install, and provides the best performance-to-complexity ratio for a cluster of this size.

doubt: what about hosting our own container registry inside the kubernetes cluster?
    Ans: This is a great approach for a homelab! We can run the official `registry:2` Docker image or a more advanced solution like **Harbor**.
    - **Pros:** Total privacy, no outbound bandwidth used for image pulls, fast local pulls, and complete control over the infrastructure.
    - **Cons:** You have to manage the storage (requires Persistent Volumes), handle TLS/Ingress so Kubernetes can securely pull from it, and handle backups yourself.

doubt: how does the cluster authenticate and pull from our self-hosted registry?
    Ans: 
    1. The self-hosted registry needs to be exposed internally, ideally with TLS (using cert-manager) or configured as an "insecure registry" in the Kubernetes nodes' container runtime (like containerd).
    3. We attach this secret to our Pods or `ServiceAccount` as an `imagePullSecrets`, which tells Kubernetes how to log in and download the images.

doubt: what if we remove GitHub entirely and use Forgejo internally? Can we run our own Actions?
    Ans: Yes! This is the ultimate "Cloud Native Homelab" setup. By hosting **Forgejo** (a lightweight fork of Gitea) inside your cluster, you get a full GitHub replacement.
    - **Self-Hosted Actions:** Forgejo has built-in CI/CD called "Forgejo Actions" (which are 99% compatible with standard GitHub Actions).
    - **The Workflow:** 
      1. You push code to `git.homelab.local` (your Forgejo instance).
      2. A Forgejo Action Runner (running as a Pod in your cluster) picks up the job.
      3. The Runner builds your Go Docker image.
      4. The Runner pushes the image to Forgejo's built-in Container Registry (Packages).
      5. The Runner updates the Kubernetes manifests in the Forgejo repository.
      6. ArgoCD detects the change in Forgejo and deploys the new image!
    - **Pros:** 100% private, no reliance on Microsoft/GitHub, extremely fast since all code pulling and image pushing happens on the local network. **Bonus:** Forgejo includes a built-in Container Registry (called Packages), so you do not need to deploy a separate registry like Harbor or `registry:2`!
    - **Cons:** You are now responsible for the uptime of your Git server and managing the storage of your source code. You'll need to configure Forgejo Runners to have access to build Docker containers (usually via "Docker-in-Docker" or Kaniko).
