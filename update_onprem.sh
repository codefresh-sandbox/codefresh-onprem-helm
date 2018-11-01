#!/usr/bin/env bash

#release.major.minor

msg() { echo -e "\e[32mINFO ---> $1\e[0m"; }

err() { echo -e "\e[31mERR ---> $1\e[0m" ; exit 1; }

channel=${1:-dev}
new_version=${2}

version_bump() {
  old_version=$(grep version codefresh/Chart.yaml | awk -F ': ' '{print $2}')

  release=$(echo ${old_version} | awk -F '.' '{print $1}')
  major=$(echo ${old_version} | awk -F '.' '{print $2}')
  minor=$(echo ${old_version} | awk -F '.' '{print $3}')

  minor=$((minor+1))

  increased_version=$(echo ${release}.${major}.${minor})

  new_version=${new_version:-${increased_version}}

  sed -i"" -e "s/^version.*/version: ${new_version}/" codefresh/Chart.yaml

  git commit -m "CF Helm Onprem updated to ${new_version} " codefresh/Chart.yaml

  msg "Codefresh Helm Chart will be updated to ${new_version}"
}

version_bump

# save default values and .helmignore
mv -v codefresh/values.yaml codefresh/values.yaml.bak
mv -v codefresh/.helmignore codefresh/.helmignore.bak

# copy on-prem values and helmignore instead default
yamlreader codefresh/env/on-prem/values.yaml codefresh/env/production/versions.yaml > codefresh/values.yaml
cp codefresh/.helmignore.onprem codefresh/.helmignore


helm dependency update --skip-refresh codefresh

package=$(echo $(helm package codefresh) | awk -F ': ' '{print $2}')

# restore defaults
mv -v codefresh/values.yaml.bak codefresh/values.yaml
mv -v codefresh/.helmignore.bak codefresh/.helmignore

rm -fv index.yaml

wget http://charts.codefresh.io/${channel}/index.yaml
if [[ $? == 0 && -f index.yaml ]]; then
   MERGE_INDEX="--merge index.yaml"
fi
helm repo index . $MERGE_INDEX --url http://charts.codefresh.io/${channel}/

aws s3 cp index.yaml s3://charts.codefresh.io/${channel}/
aws s3 cp ${package} s3://charts.codefresh.io/${channel}/

msg "Codefresh Onprem updated to ${new_version}"
