#!/bin/sh
# Commands typed in the video, in order, with the output observed (OpenShell 0.1.5, 27/10/2026).
# Not meant to be run as a script: type them one by one in the terminal of the matching profile.

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
