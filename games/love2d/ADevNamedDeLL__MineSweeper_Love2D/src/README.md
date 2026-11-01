# How to Package Your Game with Love2D

![Lua](https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white)

Follow these steps to create a standalone executable for your Love2D game:

### 1. Install 7-Zip
To start, you'll need to have **7-Zip** installed. You can download it from the official website here:  
[**Download 7-Zip**](https://www.7-zip.org/)

### 2. Create a `.love` File
- Select `main.lua` and `conf.lua` files in your project folder.
- Right-click the selected files, then choose **7-Zip** > **Add to "filename_here.zip"**.

### 3. Rename the ZIP File
Once the files are zipped, rename the `.zip` file to **`name.love`**.

### 4. Download Love2D
Next, go to the official Love2D website and download the 64-bit version:  
[**Download Love2D**](https://love2d.org/)

### 5. Set Up the Love2D Folder
- Extract the downloaded Love2D zip file to a location you find convenient.
- Open the extracted folder, and locate all the files inside it.
- Move the **`name.love`** file you created earlier into this folder.

### 6. Create a Batch File to Build the EXE
- Create a new text file and add the following code to it:

    ```batch
    copy /b C:\FOLDER_ADDRESS_HERE\love.exe+%1 "%~n1.exe"
    ```

    Replace `C:\FOLDER_ADDRESS_HERE` with the actual path to `love.exe` inside the Love2D folder.

### 7. Save and Rename the Batch File
- Save the file with the name **`create_game.bat`**.

### 8. Build the Game Executable
- Drag your **`.love`** file and drop it onto the **`create_game.bat`** file.
- This will generate **`game_name.exe`** in the same folder.

### 9. Add Required DLLs
- Create a new folder for your game files.
- Copy the `game_name.exe` and the following **DLL** files into the folder of your game:

    - `love.dll`
    - `lua51.dll`
    - `mpg123.dll`
    - `msvcp120.dll`
    - `msvcr120.dll`
    - `OpenAL32.dll`
    - `SDL2.dll`

### 10. Congratulations! Your Game is Ready
Your game is now packaged as a standalone executable and ready for distribution.
