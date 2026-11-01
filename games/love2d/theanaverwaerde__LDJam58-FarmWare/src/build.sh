if [ ! -d ".venv" ]; then
	echo "Creating virtual environment..."
	python3 -m venv .venv
fi
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

cd game

makelove --config ../makelove.toml

cd ..
