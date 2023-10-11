# Copyright 2023 Adevinta

if [[ -z $GITHUB_OUTPUT ]]; then
	echo 'error: missing env var GITHUB_OUTPUT' >&2
	exit 2
fi

if [[ -z $LAVA_CONFIG ]]; then
	echo 'error: missing env var LAVA_CONFIG' >&2
	exit 2
fi

output=$(mktemp)

lava run -c "${LAVA_CONFIG}" > "${output}"
status=$?

echo "status=${status}" >> "${GITHUB_OUTPUT}"
echo "report=${output}" >> "${GITHUB_OUTPUT}"

cat "${output}"
echo "exit status ${status}"
exit $status
