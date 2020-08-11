FROM aquasec/trivy

RUN apk add --no-cache jq bash util-linux curl

WORKDIR /scan_report

COPY ./generate_scan_report.sh .