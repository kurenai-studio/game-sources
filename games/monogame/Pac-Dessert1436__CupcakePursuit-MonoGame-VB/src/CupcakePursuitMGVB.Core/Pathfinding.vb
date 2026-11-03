Imports Microsoft.Xna.Framework

''' <summary>
''' Provides A* pathfinding algorithm on a 2D grid with direction-aware navigation that 
''' prevents 180-degree turns, producing natural-looking enemy paths.
''' </summary>
Public Module Pathfinding
    Private NotInheritable Class AStarNode
        Implements IComparable(Of AStarNode)

        Public Property Position As Point
        Public Property GCost As Integer
        Public Property HCost As Integer
        Public Property FCost As Integer
        Public Property Parent As AStarNode

        Public Function CompareTo(other As AStarNode) As Integer Implements IComparable(Of AStarNode).CompareTo
            Dim fCompare = FCost.CompareTo(other.FCost)
            Return If(fCompare <> 0, fCompare, HCost.CompareTo(other.HCost))
        End Function
    End Class

    Private ReadOnly _directionOffsets As New Dictionary(Of Direction, Point) From {
        {Direction.Up, New Point(0, -1)},
        {Direction.Down, New Point(0, 1)},
        {Direction.Left, New Point(-1, 0)},
        {Direction.Right, New Point(1, 0)}
    }

    ''' <summary>
    ''' Finds the shortest path from <paramref name="start"/> to <paramref name="end"/>
    ''' using the A* algorithm with Manhattan distance heuristic.
    ''' </summary>
    ''' <param name="walkableGrid">A 2D boolean array where True indicates a walkable cell.</param>
    ''' <param name="start">The starting grid position.</param>
    ''' <param name="end">The target grid position.</param>
    ''' <returns>A list of grid positions from start to end, or Nothing if no path exists.</returns>
    Public Function FindAStarPath(walkableGrid As Boolean(,), start As Point, [end] As Point) As List(Of Point)
        Return FindAStarPath(walkableGrid, start, [end], Nothing)
    End Function

    ''' <summary>
    ''' Finds the shortest path from <paramref name="start"/> to <paramref name="end"/>
    ''' using the A* algorithm with Manhattan distance heuristic, while preventing
    ''' 180-degree turns based on the actor's current direction of movement.
    ''' </summary>
    ''' <param name="walkableGrid">A 2D boolean array where True indicates a walkable cell.</param>
    ''' <param name="start">The starting grid position.</param>
    ''' <param name="end">The target grid position.</param>
    ''' <param name="currentDir">
    ''' The actor's current direction of movement. When provided, the first step of the
    ''' path will not go in the opposite direction, preventing sudden 180-degree turns.
    ''' </param>
    ''' <returns>A list of grid positions from start to end, or Nothing if no path exists.</returns>
    Public Function FindAStarPath(walkableGrid As Boolean(,), start As Point, [end] As Point, currentDir As Direction?) As List(Of Point)
        Dim width As Integer = walkableGrid.GetLength(0)
        Dim height As Integer = walkableGrid.GetLength(1)

        Dim isInBoundsAndWalkable As Boolean =
            IsInBounds(start, width, height) AndAlso IsInBounds([end], width, height) AndAlso
            walkableGrid(start.X, start.Y) AndAlso walkableGrid([end].X, [end].Y)

        If Not isInBoundsAndWalkable Then Return Nothing
        If start = [end] Then Return New List(Of Point) From {start}

        Dim openSet As New PriorityQueue(Of AStarNode, Integer)
        Dim gCosts(width - 1, height - 1) As Integer
        Dim inClosedSet(width - 1, height - 1) As Boolean

        For i As Integer = 0 To width - 1
            For j As Integer = 0 To height - 1
                gCosts(i, j) = Integer.MaxValue
            Next j
        Next i

        Dim startH As Integer = ManhattanDistance(start, [end])
        Dim startNode As New AStarNode With {
            .Position = start,
            .GCost = 0,
            .HCost = startH,
            .FCost = startH,
            .Parent = Nothing
        }
        gCosts(start.X, start.Y) = 0
        openSet.Enqueue(startNode, startNode.FCost)

        Do Until openSet.Count = 0
            Dim currentNode = openSet.Dequeue()
            If currentNode.Position = [end] Then Return ReconstructPath(currentNode)

            If inClosedSet(currentNode.Position.X, currentNode.Position.Y) Then Continue Do
            inClosedSet(currentNode.Position.X, currentNode.Position.Y) = True

            Dim arrivalDir = ArrivalDirection(currentNode, currentDir)
            Dim neighborDirs = GetNeighborDirections(arrivalDir)

            For Each dir As Direction In neighborDirs
                Dim offset = _directionOffsets(dir)
                Dim neighborPos As New Point(
                    currentNode.Position.X + offset.X,
                    currentNode.Position.Y + offset.Y
                )

                If Not IsInBounds(neighborPos, width, height) Then Continue For
                If Not walkableGrid(neighborPos.X, neighborPos.Y) Then Continue For
                If inClosedSet(neighborPos.X, neighborPos.Y) Then Continue For

                Dim tentativeG = currentNode.GCost + 1

                If tentativeG < gCosts(neighborPos.X, neighborPos.Y) Then
                    gCosts(neighborPos.X, neighborPos.Y) = tentativeG
                    Dim hCost = ManhattanDistance(neighborPos, [end])
                    Dim neighborNode As New AStarNode With {
                        .Position = neighborPos,
                        .GCost = tentativeG,
                        .HCost = hCost,
                        .FCost = tentativeG + hCost,
                        .Parent = currentNode
                    }
                    openSet.Enqueue(neighborNode, neighborNode.FCost)
                End If
            Next dir
        Loop

        Return Nothing
    End Function

    ''' <summary>
    ''' Determines the direction of arrival at an <see cref="AStarNode"/> by examining its parent.
    ''' For the start node, returns the actor's current direction of movement.
    ''' </summary>
    ''' <param name="node">The node to determine the arrival direction for.</param>
    ''' <param name="startDir">
    ''' The actor's current direction of movement. If provided, the first step of the
    ''' path will not go in the opposite direction, preventing sudden 180-degree turns.
    ''' </param>
    ''' <returns>The direction of arrival at the node, or Nothing if the node has no parent.</returns>
    Private Function ArrivalDirection(node As AStarNode, startDir As Direction?) As Direction?
        If node.Parent Is Nothing Then Return startDir
        Dim delta As New Point(
            node.Position.X - node.Parent.Position.X,
            node.Position.Y - node.Parent.Position.Y
        )
        For Each kvp In _directionOffsets
            If kvp.Value = delta Then Return kvp.Key
        Next kvp
        Return Nothing
    End Function

    ''' <summary>
    ''' Gets the valid neighbor directions, excluding the opposite of the arrival direction
    ''' to prevent 180-degree turns. Reuses <see cref="Essentials.GetValidDirections"/>.
    ''' </summary>
    ''' <param name="arrivalDir">The direction of arrival at the node.</param>
    ''' <returns>The valid neighbor directions, excluding the opposite of the arrival direction.</returns>
    Private Function GetNeighborDirections(arrivalDir As Direction?) As Direction()
        If arrivalDir.HasValue Then
            Return arrivalDir.Value.GetValidDirections()
        End If
        Return {Direction.Up, Direction.Down, Direction.Left, Direction.Right}
    End Function

    ''' <summary>
    ''' Checks whether a grid position is within the bounds of the grid.
    ''' </summary>
    ''' <param name="pos">The position to check.</param>
    ''' <param name="width">The width of the grid.</param>
    ''' <param name="height">The height of the grid.</param>
    ''' <returns>True if the position is within the bounds of the grid, False otherwise.</returns>
    Private Function IsInBounds(pos As Point, width As Integer, height As Integer) As Boolean
        Return pos.X >= 0 AndAlso pos.X < width AndAlso pos.Y >= 0 AndAlso pos.Y < height
    End Function

    ''' <summary>
    ''' Reconstructs the path from the goal node back to the start by following parent references.
    ''' </summary>
    ''' <param name="node">The goal node to reconstruct the path from.</param>
    ''' <returns>The path from the start node to the goal node, as a list of grid positions.</returns>
    Private Function ReconstructPath(node As AStarNode) As List(Of Point)
        Dim path As New List(Of Point)
        Dim current = node
        While current IsNot Nothing
            path.Add(current.Position)
            current = current.Parent
        End While
        path.Reverse()
        Return path
    End Function
End Module