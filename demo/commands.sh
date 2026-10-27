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

# --- "Agent — models and GitLab" terminal (image terminals/agent:1) ----------------------------
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

# --- opencode through Open WebUI (shared access "openwebui"), agent terminal -----------------------
# Prepared off camera: a git repository with the project configuration of opencode (opencode/opencode.json).
mkdir -p ~/atelier && cd ~/atelier && git init -q && cp <this repository>/opencode/opencode.json .
echo $OPENWEBUI_API_KEY                 # openshell:resolve:env:v<number>_OPENWEBUI_API_KEY (a placeholder)
curl -s -H "Authorization: Bearer $OPENWEBUI_API_KEY" $OPENWEBUI_BASE_URL/api/models -o models.json   && python3 -c "import json; [print(m['id']) for m in json.load(open('models.json'))['data']]"
                                        # the models Open WebUI opens to its users (service account, role user)
opencode run "Write stats.py that draws one thousand values from a normal distribution with a fixed seed and prints their mean and standard deviation, run it with python3, then make a git commit with the message 'Statistics'."
                                        # "> build · deepseek/deepseek-v4.1-flash", file written, run, commit (about 12 s)
git log --oneline -1                    # <hash> (HEAD -> master) Statistics
curl -s -w "
HTTP %{http_code}
" -H "Authorization: Bearer $OPENWEBUI_API_KEY" $OPENWEBUI_BASE_URL/api/v1/users/
                                        # {"error":"policy_denied", ... "GET /api/v1/users/ not permitted by policy" ...}
                                        # HTTP 403: refused by OpenShell's proxy before it reaches Open WebUI
