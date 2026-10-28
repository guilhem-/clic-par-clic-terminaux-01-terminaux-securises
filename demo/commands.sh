#!/bin/sh
# Commands typed in the video, in order, with the output observed (OpenShell 0.1.5, 27/10/2026).
# Not meant to be run as a script: type them one by one in the terminal of the matching profile.

# --- Opening example: Open WebUI's assistant in "My terminal" (terminal demo-calcul, Standard profile) -------
# Prepared off camera in the volume (PyPI is allowed by the Standard profile):
pip install --user -q numpy matplotlib python-pptx
# Request typed in Open WebUI (model "DeepSeek V4.1 Flash" through OpenRouter, "My terminal" selected):
#   Compare two parametric identification methods, recursive least squares and normalized gradient, on a noisy
#   second-order ARX system. Establish their stability and convergence conditions, check them with Python
#   simulations in my terminal, with one hundred Monte Carlo runs, then turn it into an eight-slide PowerPoint
#   presentation with the plots, saved as identification.pptx.
# The assistant writes simulation.py, runs it, saves its plots in figs/, builds identification.pptx and checks the
# rendering, in seven to nine minutes. Check of the file, in the terminal:
python3 -c "from pptx import Presentation; p = Presentation('identification.pptx'); print(len(p.slides))"   # 8

# --- "Standard" terminal (image open-terminal:0.14.2) -------------------------------------------
whoami                                  # oliver (name of the Keycloak account)
pwd                                     # /sandbox/travail (the volume)
pip install --user cowsay               # downloaded from PyPI: allowed for the Python interpreter only
python3 -m cowsay -t Bonjour
curl -sS https://gitlab.com             # curl: (7) Failed to connect to gitlab.com port 443 ... Could not connect to server
curl -sS http://169.254.169.254/        # same refusal: cloud metadata (relayed as T1552.005, severe)

# --- Before the agent terminal: Oliver's personal Open WebUI key, saved as a PAT (no command, two screens) ---------
# Open WebUI: user menu > Settings > Account > API keys > Show > "Create new secret key": the key stays in a masked
#   field; "Copy API key" (never the eye button).
# Portal, "Personal tokens (PAT)": name openwebui, host open-webui.terminals.svc.cluster.local, value pasted into the
#   masked field, Save: the list shows $PAT_OPENWEBUI. The value goes straight to OpenShell (provider pat-openwebui,
#   see openshell/openwebui-pat-provider-profile.yaml); it is never stored by the portal nor visible in a terminal.
# Launch form: profile "Agent — models and GitLab", under "PAT to attach" tick "openwebui -> open-webui.terminals...".

# --- "Agent — models and GitLab" terminal (image terminals/agent:1) ----------------------------
# Alt+1, Alt+2, Alt+3 in the full-page terminal switch between the user's terminals (one tab each).
echo $GITLAB_TOKEN                      # openshell:resolve:env:v<number>_GITLAB_TOKEN (a placeholder, not the token)
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" https://gitlab.com/api/v4/user | grep -o '"username":"[^"]*"'
                                        # the token's bot account: the proxy swapped the placeholder for the value
git clone https://gitlab.com/<group>/<project>.git demo && cd demo && git log --oneline -3
curl -sS -X DELETE -H "PRIVATE-TOKEN: $GITLAB_TOKEN" https://gitlab.com/api/v4/projects/<group>%2F<project>
                                        # curl: (52) Empty reply from server: DELETE is not in the rule,
                                        # GitLab never receives the request (the token itself would be allowed)
curl -sS https://github.com             # refused
curl -sS https://pypi.org/simple/       # refused
git checkout -b demo-<timestamp> && echo "Changed from the terminal" >> README.md
git commit -qam "Demo" && git push -u origin HEAD     # pushed: git-receive-pack is allowed

# --- Administrator: remove the git-receive-pack block from the gitlab shared access, save ---------
cd demo && echo "Second try" >> README.md && git commit -qam "Demo 2" && git push
                                        # error: RPC failed; HTTP 403 ... the remote end hung up unexpectedly
# --- Administrator: put the block back, save ---------------------------------------------------
cd demo && git push                     # pushed again, nothing restarted

# --- Administrator: tick "Approvals" on the agent-gitlab profile ---------------------------------
curl -sS https://pypi.org/simple/       # still refused, but now an access request (host, program, terminal)
# --- Administrator: approve "curl -> pypi.org:443" for this terminal -------------------------------
curl -sS -o /dev/null -w "%{http_code}\n" https://pypi.org/simple/    # 200; the exception can be withdrawn

# --- Integrated terminal of the IDE (code-server), same sandbox --------------------------------
cd ~/demo && git commit -qam "From the IDE" && git push && curl -sS https://github.com
                                        # push allowed, GitHub refused

# --- Administration: recorded refusals, then the Grafana dashboard "Terminals — full monitoring" -----------------
# (active terminals, sandboxes per image, CPU / memory / disk per terminal, refused hosts and programs, MITRE ATT&CK
# techniques, allowed connections per rule, and the "cloud metadata or Kubernetes API" alert fired by the
# curl 169.254.169.254 above). The dashboard belongs to the organization's internal monitoring: not published here.

# --- opencode through Open WebUI, with Oliver's personal key (PAT "openwebui"), agent terminal --------------------
# Prepared off camera: a git repository with the project configuration of opencode (opencode/opencode.json).
mkdir -p ~/atelier && cd ~/atelier && git init -q && cp <this repository>/opencode/opencode.json .
echo $PAT_OPENWEBUI                     # openshell:resolve:env:… (a placeholder, not the key)
# A PAT carries no address: Open WebUI's in-cluster address is written out.
curl -s -H "Authorization: Bearer $PAT_OPENWEBUI" http://open-webui.terminals.svc.cluster.local:8080/api/models -o modeles.json && python3 -c "import json; [print(m['id']) for m in json.load(open('modeles.json'))['data']]"
                                        # the models Open WebUI opens to Oliver (his own rights)
opencode run "Write stats.py that draws one thousand values from a normal distribution with a fixed seed and prints their mean and standard deviation, run it with python3, then make a git commit with the message 'Statistics'."
                                        # "> build · deepseek/deepseek-v4.1-flash", file written, run, commit (about 12 s)
git log --oneline -1                    # <hash> (HEAD -> master) Statistics
curl -s -w "\nHTTP %{http_code}\n" -H "Authorization: Bearer $PAT_OPENWEBUI" http://open-webui.terminals.svc.cluster.local:8080/api/v1/users/
                                        # {"error":"policy_denied", ... "GET /api/v1/users/ not permitted by policy" ...}
                                        # HTTP 403: refused by OpenShell's proxy before it reaches Open WebUI
# Open WebUI, administrator: Admin panel > Users, column "Last active": Oliver's last activity follows his agent's
# calls (each request authenticated with his key updates it). Open WebUI's Analytics only count chat messages.

# --- Open WebUI, "My terminal" = the agent terminal (portal button "Default") ------------------------------------
# Request: "In my demo folder, show the last three commits, then run curl -sS https://github.com, and sum up what
# you get." Then, in the right panel, "Terminal" section (same sandbox):
ls demo && echo $GITLAB_TOKEN           # the demo folder, and still the placeholder instead of the token
