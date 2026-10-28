# Secure self-service terminals — OpenShell network policy tested live

Demo material for the single video of the "Click by Click" series **Secure terminals for your users**:
Linux terminals and VS Code in the browser, launched by the users of an organization themselves, each one
in an [OpenShell](https://github.com/NVIDIA/OpenShell) sandbox whose **security profile** decides what is
allowed — files (Landlock), programs, network hosts and HTTP methods (OpenShell's proxy).

It opens with an example: Open WebUI's assistant, working in "My terminal", compares two parametric identification
methods with real Python simulations (one hundred Monte Carlo runs) and delivers an eight-slide presentation,
downloaded from the terminal's file explorer — why letting an AI run code is worth it (speed, repeatability, data
volumes), and why it must run somewhere safe.

The video then tests the policy from the terminal, with real commands:

- an organization's GitLab token (PAT) that the terminal **never reads**: `$GITLAB_TOKEN` only holds a
  placeholder (`openshell:resolve:env:…`), replaced by the proxy, and only towards `gitlab.com`;
- the same token allows `git clone` and `git push`, but a `DELETE` request is cut by the proxy before it
  reaches GitLab — even though the token itself is allowed to delete the project;
- the rule is changed **while the terminal runs**: the `git-receive-pack` block is removed, the same push
  is refused (`HTTP 403`), the block is put back, the push goes through again;
- an administrator approves an access request (`curl` → `pypi.org`) for one terminal only, then withdraws it;
- every refusal is recorded and classified (MITRE ATT&CK technique, severity), and followed in a Grafana dashboard
  with its alerts (the cloud metadata alert fires on the `curl 169.254.169.254` of the first terminal);
- an [opencode](https://opencode.ai) agent in the sandbox calls its models **through Open WebUI with the user's own
  API key**: created by the user in Open WebUI, saved in the portal as a personal token (PAT `openwebui`) and
  attached at launch, it is never readable in the terminal (`$PAT_OPENWEBUI` only holds a placeholder). The calls
  are made under the user's account, with the user's rights, and are attributed to the user (Open WebUI's "Last
  active" column). The agent writes a script, runs it and commits it; an Open WebUI admin route with the same key is
  refused by the proxy (`policy_denied`, HTTP 403).

Video: {{video}}

## Files

| File | Content |
|---|---|
| `shared-access/gitlab.yaml` | The "gitlab" shared access shown on screen: variable seen by the terminal, git identity, host, allowed requests, allowed programs |
| `opencode/opencode.json` | Project configuration of opencode: the `openwebui` provider (`@ai-sdk/openai`, Responses API, Open WebUI's in-cluster address written out, key `{env:PAT_OPENWEBUI}`) and the model pinned for every agent |
| `profiles/agent-gitlab.yaml` | Profile "Agent — models and GitLab" (version 2): the `openrouter` and `gitlab` shared accesses, and its own `openwebui` rule (three model routes, `opencode` and `curl` only) where the user's PAT is bound; `approvals` ticked in the video |
| `openshell/openwebui-pat-provider-profile.yaml` | Provider profile of the personal token `openwebui` (variable `PAT_OPENWEBUI`), with no host |
| `profiles/standard.yaml` | Profile "Standard": PyPI and npm for their interpreters only, GitHub read-only |
| `openshell/agent-gitlab-policy.yaml` | The effective OpenShell policy of the agent terminal (GitLab part), as the service composes it: the access rule with `credential_binding` on its endpoint |
| `openshell/gitlab-provider-profile.yaml` | Provider profile with no host (credential only), imported in the user's workspace |
| `demo/commands.sh` | Every command typed in the video, in order, with the output observed |
| `.env.example` | The values you need (GitLab token, demo repository, your personal Open WebUI API key), empty |

The portal, its API and its administration screens, and the Grafana dashboard, belong to the organization's
internal service and are not published here. The YAML files above use English keys; the service shown in the video uses the same structure
with French keys (`nom`, `regle`, `acces`…). The OpenShell parts (`endpoints`, `rules`, `binaries`,
`filesystem_policy`, `credential_binding`) are OpenShell's own format and work as is.

## Prerequisites

- An OpenShell 0.1.5 gateway (alpha) on Kubernetes, and its CLI connected to it (`openshell`).
- An image with `/bin/sh`, `git` and `curl`, for example `python:3.12` with git and curl added.
- A GitLab project for the demo and a **project access token** (role Owner or Maintainer, scopes `api` and
  `write_repository`). Never use a token that can reach real projects.

## Reproduce the policy test without the portal

```bash
# 1. A workspace, the provider profile and the provider holding the real token (read from your environment:
#    the value goes to OpenShell's encrypted store, never to the sandbox).
openshell workspace create --name demo
openshell --workspace demo profile import -f openshell/gitlab-provider-profile.yaml
export GITLAB_TOKEN=<your project access token>        # in YOUR shell, not in the sandbox
openshell --workspace demo provider create --name access-gitlab --type access-gitlab --credential GITLAB_TOKEN
unset GITLAB_TOKEN

# 2. A sandbox with the effective policy and the provider attached.
openshell --workspace demo sandbox create --name demo-agent --from <image with git and curl> \
  --policy openshell/agent-gitlab-policy.yaml --provider access-gitlab --tty

# 3. In the sandbox: the commands of demo/commands.sh (agent part).
echo $GITLAB_TOKEN                                     # a placeholder, not the token
git -c credential.https://gitlab.com.helper='!f() { echo username=oauth2; echo "password=$GITLAB_TOKEN"; }; f' \
  clone https://gitlab.com/<group>/<project>.git demo

# 4. Change the rule while the sandbox runs (remove the git-receive-pack line), then push again:
openshell --workspace demo policy set demo-agent --policy openshell/agent-gitlab-policy.yaml --wait
```

### Models through Open WebUI with your own key (opencode)

1. In Open WebUI, signed in with **your own account**, create your API key: user menu > Settings > Account > API keys
   > Show > "Create new secret key" (`ENABLE_API_KEYS` and the `features.api_keys` permission must be on). The key
   stays in a masked field: copy it with "Copy API key", never display it. "Create new key" later invalidates the
   previous one. Your calls are then made under your account, with your rights on the models.
2. Save it as a personal token (PAT): in the service, the portal's "Personal tokens (PAT)" section (name
   `openwebui`, host `open-webui.terminals.svc.cluster.local`), then tick it under "PAT to attach" when launching an
   "Agent — models and GitLab" terminal. Without the portal: import `openshell/openwebui-pat-provider-profile.yaml`,
   create the provider from your environment (`export PAT_OPENWEBUI=…` in **your** shell, then
   `openshell --workspace demo provider create --name pat-openwebui --type pat-openwebui --credential PAT_OPENWEBUI`),
   add the `openwebui` rule of `profiles/agent-gitlab.yaml` to the sandbox policy with
   `credential_binding: {provider: pat-openwebui}` on its endpoint, and attach the provider (`--provider pat-openwebui`).
   Adapt the host to your Open WebUI service.
3. In the sandbox, put `opencode/opencode.json` at the root of a git repository and run `opencode run "…"`. A PAT
   carries no address: the in-cluster address of Open WebUI is written in the file (and in the `curl` commands).
   opencode uses the Responses API (`/openai/responses`): Open WebUI serves OpenRouter models in "responses" mode.
   If an image ships a managed `/etc/opencode/opencode.json`, its `model` wins over the project's: the project file
   therefore pins the model per agent (`build`, `plan`, `title`, `summary`, `compaction`).

In the service, git gets the placeholder through the same credential helper, set by `GIT_CONFIG_*` variables,
and a shared access changed in the portal is applied to every running terminal that uses it (`policy set`),
in about eight seconds.

## What the video shows, and what it does not

- Shown: Open WebUI's assistant computing in "My terminal" and the presentation it produces, single sign-on with Keycloak, a terminal launched from a profile / image / volume triplet, the
  full-page terminal (xterm.js) and its tabs (Alt+1, Alt+2…), the IDE (code-server) in the same sandbox, the "My
  terminal" connection used by Open WebUI and its "Terminal" panel, shared accesses, a personal Open WebUI key saved
  as a PAT, access requests, recorded refusals and the Grafana dashboard, and opencode calling its models through
  Open WebUI with that key; Oliver's "Last active" time in Open WebUI's user list, seen by its administrator.
- Not shown: the IDE on its own origin per terminal (in the service's code, not yet in the version filmed),
  file refusals (Landlock refusals are not logged by OpenShell 0.1.5), a per-user consumption report for API calls
  (Open WebUI's Analytics only count chat messages; its audit log, not enabled here, names the user of each request),
  the per-person rows of the Grafana dashboard (service metrics not yet deployed: people appear under their OpenShell
  workspace, `u-…`).
- Limits observed: on first use in a volume, opencode tries `registry.npmjs.org` (refused, harmless: the provider is
  built into the binary); models served by direct Anthropic or Gemini connections in Open WebUI did not answer on the
  day of recording (unrelated to the terminals) — OpenRouter models did. Right after a launch, the console needs a few seconds before Open Terminal answers; a `DELETE`
  cut by the proxy is not reported in OpenShell's logs, a refused push is (`HTTP:POST … DENIED`).

## Series

This is the only module of the series: the whole tour in one video. Related series on the same channel:
image generation in Open WebUI with ComfyUI ([module 1](https://github.com/guilhem-/clic-par-clic-comfyui-01-brancher)).

## License

MIT — see `LICENSE`.
