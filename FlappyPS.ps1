## SFML assemblies must be loaded before running: .\LoadSFML.ps1

# Classes -----------------------------------------------------------------------------

# Player
Class Player : SFML.Graphics.Drawable
{
    [SFML.Graphics.RectangleShape]$shape
	[float]$height
	[float]$yVel
	
	[bool]$dead
  
	# Constructor
	Player () {
		$this.dead = $FALSE
	
        $this.height = 300
		$this.yVel = 0.1
        $size = New-Object -TypeName SFML.System.Vector2f -ArgumentList 32, 32
        
        $this.shape = New-Object -TypeName SFML.Graphics.RectangleShape -ArgumentList $size
		$this.shape.Origin = New-Object -TypeName SFML.System.Vector2f -ArgumentList 16, 16
        $this.shape.Position = New-Object -TypeName SFML.System.Vector2f -ArgumentList 300, $this.height
        $this.shape.FillColor = [SFML.Graphics.Color]::Blue
    }
    
	# SFML.Drawable.Draw() override
    Draw ([SFML.Graphics.RenderTarget]$target, [SFML.Graphics.RenderStates]$states) {
        $target.Draw($this.shape)
    }

    Update () {
		$this.yVel += 0.13
		$this.height += $this.yVel
		$this.shape.Position = New-Object -TypeName SFML.System.Vector2f -ArgumentList $this.shape.Position.X, $this.height
	}
	
	Flap() {
		$this.yVel = -4
	}
	
	Die() {
		If ($this.dead -eq $FALSE) {
			$this.dead = $TRUE
			$this.yVel = 20
			Write-Host Oops, you died.
		}
	}
	
	[SFML.Graphics.FloatRect]GetBounds () {
		Return $this.shape.GetGlobalBounds()
	}
}


# Wall
Class Wall : SFML.Graphics.Drawable
{
	[SFML.Graphics.RectangleShape]$top
	[SFML.Graphics.RectangleShape]$bottom
	
	[float]$openingHeight
	[float]$openingY
	
	[float]$x
	
	[bool]$passed
	
	# Constructor
	Wall ($beginX) {
		$this.openingHeight = 150
		$width = 60
		
		$this.x = $beginX
		
		$this.openingY = Get-Random -Maximum 500 -Minimum 100
		
		$this.passed = $FALSE
		
		$this.top = New-Object -TypeName SFML.System.Vector2f -ArgumentList $width, ($this.openingY - ($this.openingHeight / 2))
		$this.top.FillColor = [SFML.Graphics.Color]::Red
		
		$this.bottom = New-Object -TypeName SFML.System.Vector2f -ArgumentList $width, 600
		$this.bottom.FillColor = [SFML.Graphics.Color]::Red
	}
	
	# Whether either wall is colliding with the player
	[bool]TestCollision ($player) {
		If ($player.GetBounds().Intersects($this.top.GetGlobalBounds()) -Or $player.GetBounds().Intersects($this.bottom.GetGlobalBounds())) {
			Return $TRUE
		}
		Else {
			Return $FALSE
		}
	}
	
	# SFML.Drawable.Draw() override
    Draw ([SFML.Graphics.RenderTarget]$target, [SFML.Graphics.RenderStates]$states) {
        $target.Draw($this.top)
		$target.Draw($this.bottom)
    }
	
	Update () {	
		$this.x += $Global:xSpeed
		
		$this.top.Position = New-Object -TypeName SFML.System.Vector2f -ArgumentList $this.x, 0
		$this.bottom.Position = New-Object -TypeName SFML.System.Vector2f -ArgumentList $this.x, ($this.openingY + ($this.openingHeight / 2))
		
		If ($this.x -lt 300 -And $this.passed -eq $FALSE) {
			$this.passed = $TRUE
			$Global:score++
			$Global:window.SetTitle("FlappyPS - Score: " + $Global:score)
		}

		# todo: collision
	}
	
}

# Global Variables -----------------------------------------------------------------------

# Speed at which the walls are moving
$Global:xSpeed = -2

$Global:player = New-Object -TypeName Player

# Create a list of 5 walls, 300px apart
$Global:wallList = New-Object -TypeName System.Collections.Generic.List[Wall]

For ($i = 0; $i -lt 5; $i++) {
	$wallList.Add( (New-Object -TypeName Wall -ArgumentList (600 + (300 * $i))) )
}

$Global:score = 0

$Global:window = New-Object -TypeName SFML.Graphics.RenderWindow -ArgumentList (New-Object SFML.Window.VideoMode -ArgumentList 600, 600, 32), "FlappyPS", ([SFML.Window.Styles]::Close)
$Global:window.SetFramerateLimit(60)

# Global Functions -------------------------------------------------------------------

# Wall Reset
Function global:WallReset () {
	
	# If the first wall is off the screen, regenerate and move to end of list
	$thisWall = $wallList[0]
	
	If ($thisWall.x -le (-60)) {
		$wallList.Remove($thisWall)
	
		$thisWall = New-Object -TypeName Wall -ArgumentList ($wallList[3].x + 300)
		$wallList.Add($thisWall)
	}
}

# Key Handler
Function global:ProcessKey ($key) {
	Switch ($key)
	{
		Escape	{ $window.Close() }
		Space	{ $player.Flap() }
	}
}

# Events --------------------------------------------------------------------------

Register-ObjectEvent -InputObject $window -EventName Closed -Action { $sender.Close() }
Register-ObjectEvent -InputObject $window -EventName KeyPressed -Action { ProcessKey($EventArgs.Code) }

# Main Loop -----------------------------------------------------------------------

While ($window.IsOpen -eq $TRUE)
{
    $window.DispatchEvents()
    
	$window.Clear([SFML.Graphics.Color]::Cyan)
	
	$player.Update()
	
	ForEach ($wall in $wallList) {
		$wall.Update()
		$window.Draw($wall)
		
		If ($wall.TestCollision($player) -Or $player.height -gt 630) {
			$player.Die()
			$Global:xSpeed = 0
			$window.SetTitle("FlappyPS - Score: " + $Global:score + " - Dead. Press Esc to close.")
		}
	}

	$window.Draw($player)
	
	WallReset
	
    $window.Display()
}