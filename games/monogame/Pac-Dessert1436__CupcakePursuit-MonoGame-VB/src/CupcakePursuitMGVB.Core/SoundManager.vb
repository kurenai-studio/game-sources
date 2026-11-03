Imports Microsoft.Xna.Framework
Imports Microsoft.Xna.Framework.Audio
Imports Microsoft.Xna.Framework.Media
Imports Microsoft.Xna.Framework.Content

''' <summary>
''' Manages all audio playback including background music and sound effects.
''' </summary>
Public NotInheritable Class SoundManager
    Implements IDisposable

    Private _previousLives As Integer = STARTING_LIVES
    Private ReadOnly _content As ContentManager

    ' Sound effects
    Private _sndSeedPacket As SoundEffect
    Private _sndPesticide As SoundEffect
    Private _sndEnemyKilled As SoundEffect
    Private _sndEnemyRespawn As SoundEffect
    Private _sndGameStart As SoundEffect
    Private _sndAtNextLevel As SoundEffect
    Private _sndGameOver As SoundEffect
    Private _sndLifeLost As SoundEffect
    Private _sndLifeGained As SoundEffect
    Private _sndLevelCleared As SoundEffect

    ' Background music
    Private _bgmMainTheme As Song
    Private _isMusicPlaying As Boolean = False
    Private disposedValue As Boolean

    Public Sub New(content As ContentManager)
        _content = content
        LoadSounds()
        SetupEventHandlers()
    End Sub

    ''' <summary>
    ''' Loads all sound assets.
    ''' </summary>
    Private Sub LoadSounds()
        ' Load sound effects
        _sndSeedPacket = _content.Load(Of SoundEffect)("Sounds/seed_packet")
        _sndPesticide = _content.Load(Of SoundEffect)("Sounds/pesticide")
        _sndEnemyKilled = _content.Load(Of SoundEffect)("Sounds/enemy_killed")
        _sndEnemyRespawn = _content.Load(Of SoundEffect)("Sounds/enemy_respawn")
        _sndGameStart = _content.Load(Of SoundEffect)("Sounds/game_start")
        _sndAtNextLevel = _content.Load(Of SoundEffect)("Sounds/at_next_level")
        _sndGameOver = _content.Load(Of SoundEffect)("Sounds/game_over")
        _sndLevelCleared = _content.Load(Of SoundEffect)("Sounds/level_cleared")
        _sndLifeLost = _content.Load(Of SoundEffect)("Sounds/life_lost")
        _sndLifeGained = _content.Load(Of SoundEffect)("Sounds/life_gained")

        ' Load background music
        _bgmMainTheme = _content.Load(Of Song)("Sounds/BGM/main_theme")
    End Sub

    ''' <summary>
    ''' Sets up event handlers for game events.
    ''' </summary>
    Private Sub SetupEventHandlers()
        AddHandler GameStateChanged, AddressOf OnGameStateChanged
        AddHandler SeedCollected, AddressOf OnSeedCollected
        AddHandler PesticideCollected, AddressOf OnPesticideCollected
        AddHandler EnemyKilled, AddressOf OnEnemyKilled
        AddHandler EnemyRespawned, AddressOf OnEnemyRespawned
        AddHandler GameHasEnded, AddressOf OnGameHasEnded
        AddHandler LifeLost, AddressOf OnLifeLost
        AddHandler LivesChanged, AddressOf OnLivesChanged
        AddHandler LevelCleared, AddressOf OnLevelCleared
        AddHandler GetReadyMessage, AddressOf OnGetReadyMessage
        AddHandler GameStart, AddressOf OnGameStart
        AddHandler GameHasBegun, AddressOf OnGameHasBegun
        AddHandler DeathAnimationComplete, AddressOf OnDeathAnimationComplete
        AddHandler MovingToNextLevel, AddressOf OnMovingToNextLevel
        AddHandler TreeGrown, AddressOf OnTreeGrown
    End Sub

    ''' <summary>
    ''' Handles game state changes for audio.
    ''' </summary>
    Private Sub OnGameStateChanged(newState As GameState)
        Select Case newState
            Case GameState.Playing
                ResumeMusicOnPause()
            Case GameState.GameOver
                StopBackgroundMusic()
            Case GameState.Title
                _previousLives = STARTING_LIVES
                StopBackgroundMusic()
            Case GameState.Paused
                MediaPlayer.Pause()
            Case GameState.LevelCleared
                StopBackgroundMusic()
        End Select
    End Sub

    ''' <summary>
    ''' Handles game beginning for audio.
    ''' </summary>
    Private Sub OnGameHasBegun()
        PlayBackgroundMusic()
    End Sub

    ''' <summary>
    ''' Handles death animation complete for audio.
    ''' </summary>
    Private Sub OnDeathAnimationComplete()
        ResumeMusicOnPause()
    End Sub

    ''' <summary>
    ''' Handles get ready message for audio.
    ''' </summary>
    Private Sub OnGetReadyMessage()
        ResumeMusicOnPause()
    End Sub

    ''' <summary>
    ''' Handles game start sound.
    ''' </summary>
    Private Sub OnGameStart()
        _sndGameStart.Play()
    End Sub

    ''' <summary>
    ''' Handles sound on moving to next level.
    ''' </summary>
    Private Sub OnMovingToNextLevel()
        _sndAtNextLevel.Play()
    End Sub

    ''' <summary>
    ''' Handles seed collection sound.
    ''' </summary>
    Private Sub OnSeedCollected(seed As Actor.Seed)
        _sndSeedPacket.Play()
    End Sub

    ''' <summary>
    ''' Handles pesticide collection sound.
    ''' </summary>
    Private Sub OnPesticideCollected()
        _sndPesticide.Play()
    End Sub

    ''' <summary>
    ''' Handles enemy killed sound.
    ''' </summary>
    Private Sub OnEnemyKilled(enemy As Actor.Enemy)
        _sndEnemyKilled.Play()
    End Sub

    ''' <summary>
    ''' Handles enemy respawned sound.
    ''' </summary>
    Private Sub OnEnemyRespawned(enemy As Actor.Enemy)
        _sndEnemyRespawn.Play()
    End Sub

    ''' <summary>
    ''' Handles player death sound.
    ''' </summary>
    Private Sub OnGameHasEnded()
        _sndGameOver.Play()
        StopBackgroundMusic()
        _previousLives = STARTING_LIVES
    End Sub

    ''' <summary>
    ''' Handles life lost sound.
    ''' </summary>
    Private Sub OnLifeLost()
        _sndLifeLost.Play()
        MediaPlayer.Pause()
    End Sub

    ''' <summary>
    ''' Handles life gained sound.
    ''' </summary>
    Private Sub OnLivesChanged(lives As Integer)
        If lives > _previousLives Then _sndLifeGained.Play()
        _previousLives = lives
    End Sub

    ''' <summary>
    ''' Handles level cleared sound.
    ''' </summary>
    Private Sub OnLevelCleared()
        _sndLevelCleared.Play()
    End Sub

    ''' <summary>
    ''' Handles tree grown sound.
    ''' </summary>
    Private Sub OnTreeGrown(position As Point)
        _sndSeedPacket.Play(0.5F, 0.0F, 0.0F)
    End Sub

    ''' <summary>
    ''' Starts playing background music.
    ''' </summary>
    Private Sub PlayBackgroundMusic()
        If Not _isMusicPlaying Then
            MediaPlayer.Play(_bgmMainTheme)
            MediaPlayer.IsRepeating = True
            _isMusicPlaying = True
        ElseIf MediaPlayer.State = MediaState.Paused Then
            MediaPlayer.Resume()
        End If
    End Sub

    ''' <summary>
    ''' Stops background music.
    ''' </summary>
    Private Sub StopBackgroundMusic()
        If _isMusicPlaying Then
            MediaPlayer.Stop()
            _isMusicPlaying = False
        End If
    End Sub

    ''' <summary>
    ''' Resumes background music on paused state.
    ''' </summary>
    Private Sub ResumeMusicOnPause()
        If _isMusicPlaying AndAlso MediaPlayer.State = MediaState.Paused Then
            MediaPlayer.Resume()
        End If
    End Sub

    ''' <summary>
    ''' Disposes of sound resources.
    ''' </summary>
    Private Sub Dispose(disposing As Boolean)
        If Not disposedValue Then
            If disposing Then
                RemoveHandler GameStateChanged, AddressOf OnGameStateChanged
                RemoveHandler SeedCollected, AddressOf OnSeedCollected
                RemoveHandler PesticideCollected, AddressOf OnPesticideCollected
                RemoveHandler EnemyKilled, AddressOf OnEnemyKilled
                RemoveHandler EnemyRespawned, AddressOf OnEnemyRespawned
                RemoveHandler GameHasEnded, AddressOf OnGameHasEnded
                RemoveHandler LifeLost, AddressOf OnLifeLost
                RemoveHandler LivesChanged, AddressOf OnLivesChanged
                RemoveHandler LevelCleared, AddressOf OnLevelCleared
                RemoveHandler GetReadyMessage, AddressOf OnGetReadyMessage
                RemoveHandler GameStart, AddressOf OnGameStart
                RemoveHandler GameHasBegun, AddressOf OnGameHasBegun
                RemoveHandler DeathAnimationComplete, AddressOf OnDeathAnimationComplete
                RemoveHandler MovingToNextLevel, AddressOf OnMovingToNextLevel
                RemoveHandler TreeGrown, AddressOf OnTreeGrown

                StopBackgroundMusic()
            End If

            disposedValue = True
        End If
    End Sub

    ''' <summary>
    ''' Disposes of sound resources.
    ''' </summary>
    Public Sub Dispose() Implements IDisposable.Dispose
        Dispose(disposing:=True)
        GC.SuppressFinalize(Me)
    End Sub
End Class