''' <summary>
''' Contains hardcoded values for the game.
''' </summary>
Public Module HardcodedValues
    Public ReadOnly Property AllMazeLayouts As XElement
        Get
            ' '#' = border; ' ' = floor; '@' = cupcake; numbers = decoration
            ' This XML literal for the game's maze layouts is currently undone.
            Dim xml = <?xml version="1.0" encoding="utf-8" standalone="yes"?>
                      <AllMazeLayouts>
                          <MazeLayout Level="1">
                              <Tiles>#####################</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#####################</Tiles>
                          </MazeLayout>
                          <MazeLayout Level="2">
                              <Tiles>#####################</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#                   #</Tiles>
                              <Tiles>#####################</Tiles>
                          </MazeLayout>
                      </AllMazeLayouts>

            Dim result As XElement = xml.Root
#Region "Validate Each Maze Layout"
            For Each layout In result.<MazeLayout>
                Dim tilesList = layout.<Tiles>.ToList()
                Dim rowCount = tilesList.Count
                Dim failures As New List(Of String)

                ' Check row count
                If rowCount <> MAZE_HEIGHT Then
                    failures.Add($"Expected {MAZE_HEIGHT} rows, but found {rowCount}")
                End If

                ' Check column widths
                For i As Integer = 0 To tilesList.Count - 1
                    Dim colCount = tilesList(i).Value.Length
                    If colCount <> MAZE_WIDTH Then failures.Add(
                        $"Row {i + 1} has {colCount} columns, expected {MAZE_WIDTH}")
                Next i

                If failures.Count > 0 Then Throw New ArgumentException(
                    $"MazeLayout in Level {layout.@Level} has validation failures:" & 
                    vbCrlf & String.Join(vbCrLf, failures))
            Next layout
#End Region

            Return result
        End Get
    End Property
End Module