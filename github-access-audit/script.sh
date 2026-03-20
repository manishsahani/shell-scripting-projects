#!/bin/bash

ORG="your-org-name"
REPO="your-repo-name"
TOKEN="your_github_token"

OUTPUT="github_access_report.csv"

echo "username,access_type,source,permission" > $OUTPUT

echo "Fetching organization members..."

# ORG MEMBERS
page=1
while true; do
  response=$(curl -s -H "Authorization: token $TOKEN" \
    "https://api.github.com/orgs/$ORG/members?per_page=100&page=$page")

  users=$(echo "$response" | jq -r '.[].login')

  [ -z "$users" ] && break

  for user in $users; do
    echo "$user,org_member,organization,default" >> $OUTPUT
  done

  ((page++))
done

echo "Fetching teams..."

# TEAMS + MEMBERS
teams=$(curl -s -H "Authorization: token $TOKEN" \
  "https://api.github.com/orgs/$ORG/teams" | jq -r '.[].slug')

for team in $teams; do
  echo "Processing team: $team"

  members=$(curl -s -H "Authorization: token $TOKEN" \
    "https://api.github.com/orgs/$ORG/teams/$team/members" \
    | jq -r '.[].login')

  for user in $members; do
    echo "$user,team_member,$team,team_access" >> $OUTPUT
  done
done

echo "Fetching repo collaborators..."

# REPO COLLABORATORS
collaborators=$(curl -s -H "Authorization: token $TOKEN" \
  "https://api.github.com/repos/$ORG/$REPO/collaborators" \
  | jq -r '.[] | "\(.login),\(.permissions)"')

while IFS=, read -r user perms; do
  echo "$user,repo_collaborator,$REPO,$perms" >> $OUTPUT
done <<< "$collaborators"

echo "Report generated: $OUTPUT"
