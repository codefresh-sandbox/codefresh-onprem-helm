# ----- Sops ------
#
FROM golang:1.8-alpine3.6 AS sops
# install sops
RUN apk add --no-cache git && go get -u go.mozilla.org/sops/cmd/sops && which sops

#------ drone-helm ----
FROM alexeiled/drone-helm:2.5.1 as helm


#------- Deployer ------
#
FROM google/cloud-sdk:alpine

COPY --from=sops /go/bin/sops /usr/bin/
COPY --from=helm /bin/helm /usr/bin/
COPY --from=helm /bin/kubectl /usr/bin/
COPY --from=helm /bin/drone-helm /usr/bin/
COPY entrypoint.sh /usr/bin
RUN chmod +x /usr/bin/entrypoint.sh

CMD [ "entrypoins.sh" ]