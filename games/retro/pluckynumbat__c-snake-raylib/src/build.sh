# build system for the project to run the cmake steps

targetName="c_snake"

echo "step 1: generate the make file..."
result1=$(cmake -B build)

if [[ $result1 =~ "errors occurred!" ]]; then
	echo "step 1: failed, abort"
	exit 1
fi

echo "step 2: build the target (and its dependencies)..."
result2=$(cmake --build build)

if ! [[ $result2 == *"Built target $targetName"* ]]; then
	echo "step 2: failed, abort"
	exit 1
fi
		
echo "step 3: run the game!"
./build/c_snake