# Copyright 2023 Adevinta

GH_DOWNLOAD_URL_FMT='https://github.com/adevinta/lava/releases/download/%s/lava_linux_amd64.tar.gz'
GH_DOWNLOAD_URL_LATEST='https://github.com/adevinta/lava/releases/latest/download/lava_linux_amd64.tar.gz'

install_lava() {
	local version=$1

	local url
	if [[ $version == 'latest' ]]; then
		url=$GH_DOWNLOAD_URL_LATEST
	else
		url=$(printf "${GH_DOWNLOAD_URL_FMT}" "${version}")
	fi

	# Make sure the install directory exists.
	install_dir="$(go env GOPATH)/bin"
	mkdir -p "${install_dir}"

	# Try to download a Lava release from GitHub.
	if (curl -LsSf "${url}" | tar -xz -C "${install_dir}" lava) 2> /dev/null; then
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

# Install Lava.

if ! install_lava "${LAVA_VERSION}"; then
	echo 'error: could not install lava' >&2
	exit 1
fi

# Run Lava.

config=${LAVA_CONFIG:-"${GITHUB_ACTION_PATH}/default.yaml"}
output=$(mktemp)

lava scan -forcecolor="${LAVA_FORCECOLOR}" -c "${config}" > "${output}"
status=$?

echo "status=${status}" >> "${GITHUB_OUTPUT}"
echo "report=${output}" >> "${GITHUB_OUTPUT}"

cat "${output}"
echo "exit status ${status}"
exit $status
