#!/bin/bash

if [ ${#} -ne 2 ]; then
	echo "ERROR: Please provide 2 arguments" >&2
	exit 1
fi

suite_file=${1}
program=${2}

for suite in $(cat "${suite_file}"); do
	if [ ! -r "${suite}.expect" ]; then
		echo "ERROR: The ${suite}.expect file does not exists or is not readable" >&2
		exit 1
	fi

	TEMPFILE=$(mktemp)
	args=""

	if [ -r "${suite}.args" ]; then
		args=$(cat "${suite}.args")
	fi

	if [ -r "${suite}.in" ]; then
		"${program}" ${args} < "${suite}.in" > "${TEMPFILE}"
	else
		"${program}" ${args} > "${TEMPFILE}"
	fi

	diff "${TEMPFILE}" "${suite}.expect" > /dev/null
	if [ ${?} -ne 0 ]; then
		echo "Test failed: ${suite}"
		echo "Args:"
		if [ -r "${suite}.args" ]; then
			cat "${suite}.args"
		fi
		echo "Input:"
		if [ -r "${suite}.in" ]; then
			cat "${suite}.in"
		fi
		echo "Expected:"
		cat "${suite}.expect"
		echo "Actual:"
		cat ${TEMPFILE}
	fi

	rm "${TEMPFILE}"

done

exit 0