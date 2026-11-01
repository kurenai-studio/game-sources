package utils

import (
	"encoding/gob"
	"os"
)

const dataFile = ".gamedata"

type GameData struct {
	HiScore int
}

func LoadData() (*GameData, error) {
	gameData := &GameData{}
	file, err := os.Open(dataFile)
	if err != nil {
		if os.IsNotExist(err) {
			return gameData, nil
		}
		return gameData, err
	}
	defer file.Close()
	decoder := gob.NewDecoder(file)
	err = decoder.Decode(gameData)
	return gameData, err
}

func SaveData(gameData *GameData) error {
	file, err := os.Create(dataFile)
	if err != nil {
		return err
	}
	defer file.Close()
	encoder := gob.NewEncoder(file)
	return encoder.Encode(gameData)
}
