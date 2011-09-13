#!/bin/bash
#
# Run all common_schema tests
#

export MYSQL_USER=$1
export MYSQL_PASSWORD=$2
export MYSQL_SOCKET=$3
export MYSQL_SCHEMA=common_schema

export INITIAL_PATH=$(pwd)
export TESTS_ROOT_PATH=${INITIAL_PATH}/root

export TEST_OUTPUT_PATH=/tmp
export TEST_OUTPUT_FILE=common_schema_test_output.txt
export DIFF_OUTPUT_FILE=common_schema_test_diff.txt

cd $TESTS_ROOT_PATH

for TEST_FAMILY_PATH in $(find * -maxdepth 0 -type d)
do
	# Test family: suite of tests, testing a specific feature or feature set
	echo "Testing family: ${TEST_FAMILY_PATH}"
	cd $TESTS_ROOT_PATH/$TEST_FAMILY_PATH
	if [ -f pre.sql ] ; then
		mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET $MYSQL_SCHEMA < pre.sql
		if [ $? -ne 0 ] ; then
		  echo "Test family ${TEST_FAMILY_PATH} failed on pre.sql"
		  exit 1
		fi
	fi

	for TEST_PATH in $(find * -maxdepth 0 -type d)
	do
		# Particular test
		echo "  Testing: ${TEST_FAMILY_PATH}/${TEST_PATH}"
		cd $TESTS_ROOT_PATH/$TEST_FAMILY_PATH/$TEST_PATH
		
		# prepare test
		if [ -f pre.sql ] ; then
			mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET $MYSQL_SCHEMA < pre.sql
			if [ $? -ne 0 ] ; then
			  echo "Test ${TEST_FAMILY_PATH}/${TEST_PATH} failed on pre.sql"
			  exit 1
			fi
		fi
		
		# execute test code
		mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET $MYSQL_SCHEMA --silent --raw < test.sql > ${TEST_OUTPUT_PATH}/${TEST_OUTPUT_FILE}
		if [ $? -ne 0 ] ; then
		  echo "Test ${TEST_FAMILY_PATH}/${TEST_PATH} failed on test.sql"
		  exit 1
		fi

		# check test results
		if [ -f expected.txt ] ; then
			diff expected.txt ${TEST_OUTPUT_PATH}/${TEST_OUTPUT_FILE} > ${TEST_OUTPUT_PATH}/${DIFF_OUTPUT_FILE}
			if [ $? -ne 0 ] ; then
			  echo "Test ${TEST_FAMILY_PATH}/${TEST_PATH} failed: unexpected output. See ${TEST_OUTPUT_PATH}/${DIFF_OUTPUT_FILE}"
			  exit 1
			fi
		else
			# By default, we expect "1"
			TEST_RESULT=$(cat ${TEST_OUTPUT_PATH}/${TEST_OUTPUT_FILE})
			if [ $TEST_RESULT != "1" ] ; then
			  echo "Test ${TEST_FAMILY_PATH}/${TEST_PATH} failed: got $TEST_RESULT"
			  exit 1
			fi
		fi
	done
done
cd ${INITIAL_PATH}