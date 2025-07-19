# Creating GitHub Personal Access Token for Kubrix

## Steps to Create PAT:

1. Go to https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Give it a name: "Kubrix IDP Access"
4. Select the following scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `workflow` (Update GitHub Action workflows)
   - ✅ `read:org` (Read org and team membership)
   
5. Click "Generate token"
6. **COPY THE TOKEN IMMEDIATELY** (it won't be shown again)

## Update Your Configuration:

Once you have the token, update the .env file:

```bash
# Edit the .env file
nano .env

# Replace YOUR_GITHUB_PAT_HERE with your actual token
KUBRIX_CUSTOMER_REPO_TOKEN=ghp_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

## Alternative: Use GitHub CLI

If you prefer, you can create a token using the GitHub CLI:

```bash
gh auth refresh -h github.com -s repo,workflow,read:org
```

Then use the token from:
```bash
cat ~/.config/gh/hosts.yml | grep token
```