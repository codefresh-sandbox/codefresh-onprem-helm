#!/usr/bin/env bash

#release.major.minor

msg() { echo -e "\e[32mINFO ---> $1\e[0m"; }

err() { echo -e "\e[31mERR ---> $1\e[0m" ; exit 1; }

channel=${1:-dev}

version_bump() {
  old_version=$(grep version codefresh/Chart.yaml | awk -F ': ' '{print $2}')

  release=$(echo ${old_version} | awk -F '.' '{print $1}')
  major=$(echo ${old_version} | awk -F '.' '{print $2}')
  minor=$(echo ${old_version} | awk -F '.' '{print $3}')

  minor=$((minor+1))

  increased_version=$(echo ${release}.${major}.${minor})

  read -t10 -p "Enter new version (timeout 10 sec) [${increased_version}]: " new_version

  new_version=${new_version:-${increased_version}}

  sed -i "" -e "s/^version.*/version: ${new_version}/" codefresh/Chart.yaml

  git commit -m "CF Helm Onprem updated to ${new_version} " codefresh/Chart.yaml

  msg "Codefresh Helm Chart will be updated to ${new_version}"
}

version_bump

# save default values
mv codefresh/values.yaml codefresh/values.yaml.bak

# copy on-prem values instead default
cp codefresh/env/on-prem/values.yaml codefresh/values.yaml

helm dependency update --skip-refresh codefresh

package=$(echo $(helm package codefresh) | awk -F ': ' '{print $2}')

mv codefresh/values.yaml.bak codefresh/values.yaml

rm -f index.yaml

wget http://charts.codefresh.io/${channel}/index.yaml
helm repo index . --merge index.yaml --url http://charts.codefresh.io/${channel}/

aws s3 cp index.yaml s3://charts.codefresh.io/${channel}/
aws s3 cp ${package} s3://charts.codefresh.io/${channel}/

msg "Codefresh Onprem updated to ${new_version}"
