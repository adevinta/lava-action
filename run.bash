# Copyright 2023 Adevinta

# Check mandatory environment variables.

if [[ -z $GITHUB_ACTION_PATH ]]; then
	echo 'error: missing env var GITHUB_ACTION_PATH' >&2
	exit 2
fi

if [[ -z $GITHUB_OUTPUT ]]; then
	echo 'error: missing env var GITHUB_OUTPUT' >&2
	exit 2
fi

if [[ -z $LAVA_FORCECOLOR ]]; then
	echo 'error: missing env var LAVA_FORCECOLOR' >&2
	exit 2
fi

# Run Lava.

config=$LAVA_CONFIG
if [[ -z $config ]]; then
	config=$(mktemp -p .)
	cp "${GITHUB_ACTION_PATH}/default.yaml" "${config}"
fi

output=$(mktemp)

lava scan -forcecolor="${LAVA_FORCECOLOR}" -c "${config}" > "${output}"
status=$?

echo "status=${status}" >> "${GITHUB_OUTPUT}"
echo "report=${output}" >> "${GITHUB_OUTPUT}"

cat "${output}"
echo "exit status ${status}"
exit $status
