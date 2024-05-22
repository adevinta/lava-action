# Copyright 2023 Adevinta

GH_DOWNLOAD_URL_FMT='https://github.com/adevinta/lava/releases/download/%s/lava_linux_amd64.tar.gz'
GH_DOWNLOAD_URL_LATEST='https://github.com/adevinta/lava/releases/latest/download/lava_linux_amd64.tar.gz'
YQ_VERSION=${YQ_VERSION:-v4.44.1}

install_lava() {
	local version=$1

	local url
	if [[ $version == 'latest' ]]; then
		url=$GH_DOWNLOAD_URL_LATEST
	else
		# shellcheck disable=SC2059
		url=$(printf "${GH_DOWNLOAD_URL_FMT}" "${version}")
	fi

	# Try to download a Lava release from GitHub.
	if (curl -LsSf "${url}" | sudo tar -xz -C "/usr/local/bin" lava) 2> /dev/null; then
		return 0
	fi

	# Fallback to "go install".
	go install "github.com/adevinta/lava/cmd/lava@${version}"
}

# Check mandatory environment variables.

if [[ -z $GITHUB_ACTION_PATH ]]; then
	echo 'error: missing env var GITHUB_ACTION_PATH' >&2
	exit 2
fi

if [[ -z $GITHUB_OUTPUT ]]; then
	echo 'error: missing env var GITHUB_OUTPUT' >&2
	exit 2
fi

if [[ -z $LAVA_VERSION ]]; then
	echo 'error: missing env var LAVA_VERSION' >&2
	exit 2
fi

if [[ -z $LAVA_FORCECOLOR ]]; then
	echo 'error: missing env var LAVA_FORCECOLOR' >&2
	exit 2
fi

if [[ -n $TEST_WORKDIR ]]; then
	cd "$TEST_WORKDIR" || { echo 'error: could not cd to TEST_WORKDIR' >&2 ; exit 2; }
fi

if [[ -n $LAVA_CONFIG ]]; then
	config=$LAVA_CONFIG
elif [[ -f lava.yaml ]]; then
	config=lava.yaml
else
	config="${GITHUB_ACTION_PATH}/default.yaml"
fi

# Install Lava.

if ! install_lava "${LAVA_VERSION}"; then
	echo 'error: could not install lava' >&2
	exit 1
fi

if ! which yq &> /dev/null; then
	if ! (wget "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64.tar.gz" -O - | tar xz && sudo mv yq_linux_amd64 /usr/local/bin/yq) 2> /dev/null; then
		echo 'error: could not install yq' >&2
		exit 1
	fi
fi

# This action needs the metrics, so if not set it is forced.
metrics=$(yq '.report.metrics' "${config}")
if [[ "$metrics" == "null" ]]; then
	metrics=$(mktemp -t metrics-injected-XXXX)
	original_config=$config
	config=$(mktemp)
	metrics=$metrics yq eval '.report.metrics = strenv(metrics)' "${original_config}" > "${config}"
else
	metrics=$(realpath "$metrics")
fi

# Run Lava.

output=$(mktemp)

lava scan -c "${config}" > "${output}"
status=$?

# Restore original config
if [[ "$original_config" != "" ]]; then
	config=$original_config
fi

{
echo "status=${status}"
echo "report=${output}"
echo "config=${config}"
echo "metrics=${metrics}"
} > "${GITHUB_OUTPUT}"

cat "${output}"
echo "exit status ${status}"
exit $status
