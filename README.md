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
- every refusal is recorded and classified (MITRE ATT&CK technique, severity);
- an [opencode](https://opencode.ai) agent in the sandbox calls its models **through Open WebUI** (shared access
  `openwebui`, key of a service account that is never readable in the terminal), writes a script, runs it and
  commits it; an Open WebUI admin route with the same key is refused by the proxy (`policy_denied`, HTTP 403).

Video: {{video}}

## Files

| File | Content |
|---|---|
| `shared-access/gitlab.yaml` | The "gitlab" shared access shown on screen: variable seen by the terminal, git identity, host, allowed requests, allowed programs |
| `shared-access/openwebui.yaml` | The "openwebui" shared access: models through Open WebUI's OpenAI-compatible API, three allowed routes, `opencode` and `curl` only |
| `opencode/opencode.json` | Project configuration of opencode: the `openwebui` provider (`@ai-sdk/openai`, Responses API) and the model pinned for every agent |
| `profiles/agent-gitlab.yaml` | Profile "Agent — models and GitLab": no network of its own, only the `openrouter`, `gitlab` and `openwebui` shared accesses; `approvals` ticked in the video |
| `profiles/standard.yaml` | Profile "Standard": PyPI and npm for their interpreters only, GitHub read-only |
| `openshell/agent-gitlab-policy.yaml` | The effective OpenShell policy of the agent terminal (GitLab part), as the service composes it: the access rule with `credential_binding` on its endpoint |
| `openshell/gitlab-provider-profile.yaml` | Provider profile with no host (credential only), imported in the user's workspace |
| `demo/commands.sh` | Every command typed in the video, in order, with the output observed |
| `.env.example` | The values you need (GitLab token, demo repository, Open WebUI service account key), empty |

The portal, its API and its administration screens belong to the organization's internal service and are not
published here. The YAML files above use English keys; the service shown in the video uses the same structure
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

### Models through Open WebUI (opencode)

1. In Open WebUI, create a service account with the **user** role (never admin), sign in with it once, and create
   an API key (Settings > Account > API keys; `ENABLE_API_KEYS` must be on). The account only sees the models open
   to every user or granted to it.
2. Import `shared-access/openwebui.yaml` the same way as the GitLab access (profile of provider with
   `OPENWEBUI_API_KEY`, provider holding the key, rule added to the sandbox policy with `credential_binding`), and set
   `OPENWEBUI_BASE_URL` in the sandbox environment. Adapt the host to your Open WebUI service.
3. In the sandbox, put `opencode/opencode.json` at the root of a git repository and run `opencode run "…"`.
   opencode uses the Responses API (`/openai/responses`): Open WebUI serves OpenRouter models in "responses" mode.
   If an image ships a managed `/etc/opencode/opencode.json`, its `model` wins over the project's: the project file
   therefore pins the model per agent (`build`, `plan`, `title`, `summary`, `compaction`).

In the service, git gets the placeholder through the same credential helper, set by `GIT_CONFIG_*` variables,
and a shared access changed in the portal is applied to every running terminal that uses it (`policy set`),
in about eight seconds.

## What the video shows, and what it does not

- Shown: Open WebUI's assistant computing in "My terminal" and the presentation it produces, single sign-on with Keycloak, a terminal launched from a profile / image / volume triplet, the
  full-page terminal (xterm.js), the IDE (code-server) in the same sandbox, the "My terminal" connection used
  by Open WebUI, shared accesses, access requests, recorded refusals, and opencode calling its models through Open WebUI.
- Not shown: the IDE on its own origin per terminal (in the service's code, not yet in the version filmed),
  file refusals (Landlock refusals are not logged by OpenShell 0.1.5).
- Limits observed: on first use in a volume, opencode tries `registry.npmjs.org` (refused, harmless: the provider is
  built into the binary); models served by direct Anthropic or Gemini connections in Open WebUI did not answer on the
  day of recording (unrelated to the terminals) — OpenRouter models did. Right after a launch, the console needs a few seconds before Open Terminal answers; a `DELETE`
  cut by the proxy is not reported in OpenShell's logs, a refused push is (`HTTP:POST … DENIED`).

## Series

This is the only module of the series: the whole tour in one video. Related series on the same channel:
image generation in Open WebUI with ComfyUI ([module 1](https://github.com/guilhem-/clic-par-clic-comfyui-01-brancher)).

## License

MIT — see `LICENSE`.
